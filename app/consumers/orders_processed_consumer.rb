# frozen_string_literal: true

class OrdersProcessedConsumer < ApplicationConsumer
  class WebpayTransactionError < StandardError; end
  class ElixirServiceError < StandardError; end
  NOTIFY_URL = ENV.fetch("NOTIFY_URL", "http://localhost:4000/api/v1/payments")

  def consume
    messages.each do |message|
      process_success(message.payload)
    rescue StandardError => e
      Rails.logger.error("Error processing orders.processed message: #{e.message}")
    end
  end

  private

  def process_success(payload)
    @user_id = payload["user_id"]
    @order_id = payload["order_id"]
    @total = payload["total"].to_i

    Rails.logger.info("Processing successful order #{@order_id} for user #{@user_id}")

    @payment = Payment.create!(
      order_id: @order_id,
      user_id: @user_id,
      status: "pending",
      amount: @total
    )

    create_webpay_transaction
    notify_payment
  end

  def create_webpay_transaction
    tx = WebpayClient.transaction
    create_tx = tx.create(
      @order_id.to_s,
      "user_#{@user_id}",
      @total,
      Rails.application.routes.url_helpers.api_v1_payments_webpay_plus_commit_url
    )

    @payment.update!(
      transaction_token: create_tx["token"],
      transaction_data: create_tx.to_json
    )
  rescue WebpayTransactionError => e
    Rails.logger.error("Error creating Webpay transaction: #{e.message}")
    raise
  end

  def notify_payment
    data = JSON.parse(@payment.transaction_data || "{}")
    raise "Missing transaction data" if data["token"].blank? || data["url"].blank?

    payload = {
      payment: {
        id: @payment.id.to_s,
        user_id: @user_id.to_s
      }
    }

    response = RestClient.post(
      NOTIFY_URL,
      payload.to_json,
      { content_type: :json, accept: :json }
    )

    raise "Invalid response from Elixir service" unless response.code == 200

    Rails.logger.info("Notified payment for order #{@payment.order_id}")
  rescue RestClient::ExceptionWithResponse => e
    Rails.logger.error("Elixir Service error: #{e.response}")
    raise ElixirServiceError, e.message
  end
end
