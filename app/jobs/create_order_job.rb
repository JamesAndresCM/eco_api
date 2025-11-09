# frozen_string_literal: true

class CreateOrderJob < ApplicationJob
  class GoServiceError < StandardError; end
  class ElixirServiceError < StandardError; end
  class WebpayTransactionError < StandardError; end

  ORDER_URL = ENV.fetch("ORDER_URL", "http://localhost:8080/orders")
  NOTIFY_URL = ENV.fetch("NOTIFY_URL", "http://localhost:4000/api/v1/payments")
  queue_as :orders

  limits_concurrency to: 5, key: ->(user_id, _) { "user_orders_#{user_id}" }, duration: 5.minutes
  retry_on GoServiceError, wait: :exponentially_longer, attempts: 3
  retry_on ElixirServiceError, wait: :polynomially_longer, attempts: 2
  retry_on WebpayTransactionError, wait: :exponentially_longer, attempts: 2
  retry_on StandardError, wait: :polynomially_longer, attempts: 2

  def perform(user_id, order_params)
    @user_id = user_id
    return unless User.find_by(id: @user_id).present?

    response_data = create_order(order_params)
    Rails.logger.info("Order #{response_data['order_id']} processed in Go service, payment initialized")
    @order_id = response_data["order_id"]
    @total_amount = response_data["total"].to_i
    @payment = create_pending_payment
    create_webpay_transaction
    notify_payment
    Rails.logger.info("Order #{@order_id} and payment #{@payment.id} created successfully")
  rescue StandardError => e
    Rails.logger.error("Error processing order: #{e.message}")
    raise
  end

  private

  def create_order(order_params)
    payload = {
      user_id: @user_id,
      items: order_params["items"]
    }

    response = RestClient.post(
      ORDER_URL,
      payload.to_json,
      { content_type: :json, accept: :json }
    )

    raise "Invalid response from Go service" unless response.code == 200

    response = response.body
    Rails.logger.info("Response from Go service: #{response}")
    JSON.parse(response)
  rescue RestClient::ExceptionWithResponse => e
    Rails.logger.error("Go Service error: #{e.message}")
    raise GoServiceError, e.message
  end

  def notify_payment
    Rails.logger.info("Notifying payment for order #{@order_id}")
    data = JSON.parse(@payment.transaction_data || "{}")
    raise "Missing transaction data for payment #{@payment.id}" if data["token"].blank? || data["url"].blank?

    payload = {
      payment: {
        id: @payment.id.to_s,
        user_id: @user_id.to_s
      }
    }

    response = RestClient.post(
      NOTIFY_URL, payload.to_json,
      { content_type: :json, accept: :json }
    )
    raise "Invalid response from Elixir service" unless response.code == 200

    response = response.body
    Rails.logger.info("Response from Elixir service: #{response}")
    JSON.parse(response)
  rescue RestClient::ExceptionWithResponse => e
    Rails.logger.error("Elixir Service error: #{e.response}")
    raise ElixirServiceError, e.message
  end

  def create_pending_payment
    Payment.create!(
      order_id: @order_id,
      user_id: @user_id,
      status: "pending",
      amount: @total_amount
    )
  end

  def create_webpay_transaction
    tx = WebpayClient.transaction

    create_tx = tx.create(
      @order_id.to_s,
      "user_#{@user_id}",
      @total_amount,
      Rails.application.routes.url_helpers.api_v1_payments_webpay_plus_commit_url
    )

    @payment.update!(
      transaction_token: create_tx["token"],
      transaction_data: create_tx.to_json
    )
  rescue WebpayTransactionError => e
    Rails.logger.error("Error creating Webpay transaction: #{e.message}")
    raise WebpayTransactionError, e.message
  end
end
