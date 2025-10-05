# frozen_string_literal: true

class CreateOrderJob < ApplicationJob
  ORDER_URL = ENV.fetch("ORDER_URL", "http://localhost:8080/orders")
  queue_as :orders

  limits_concurrency to: 5, key: ->(user_id, _) { "user_orders_#{user_id}" }, duration: 5.minutes
  retry_on RestClient::ExceptionWithResponse, wait: :exponentially_longer, attempts: 3
  retry_on StandardError, wait: :polynomially_longer, attempts: 2

  def perform(user_id, order_params)
    @user_id = user_id
    return unless User.find_by(id: @user_id).present?

    response_data = create_order(order_params)
    @order_id = response_data["order_id"]
    @total_amount = response_data["total"].to_i

    @payment = create_pending_payment
    create_webpay_transaction

    Rails.logger.info("Order #{@order_id} processed in Go service, payment initialized")
  rescue RestClient::ExceptionWithResponse => e
    Rails.logger.error("Go service error: #{e.response}")
    raise
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

    JSON.parse(response.body)
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
  end
end
