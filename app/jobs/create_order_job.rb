# frozen_string_literal: true

class CreateOrderJob < ApplicationJob
  ORDER_URL = ENV.fetch("ORDER_URL", "http://localhost:8080/orders")
  queue_as :orders

  limits_concurrency to: 5, key: ->(user_id, _) { "user_orders_#{user_id}" }, duration: 5.minutes
  retry_on RestClient::ExceptionWithResponse, wait: :exponentially_longer, attempts: 3
  retry_on StandardError, wait: :polynomially_longer, attempts: 2

  def perform(user_id, order_params)
    payload = {
      user_id: user_id,
      items: order_params["items"]
    }

    response = RestClient.post(
      ORDER_URL,
      payload.to_json,
      { content_type: :json, accept: :json }
    )

    if response.code == 200
      response_data = JSON.parse(response.body)
      order_id = response_data["order_id"]
      if order_id.present?
        # https://proyecto-ejemplo-ruby.transbankdevelopers.cl/webpay-plus/create
        # TODO: integrate with payment gateway
        # when order is created successfully, call to external payment service like as transbank
        # transaction = TransbankPayment.process_payment(order_id)
        # if the transaction is successful, send data to elixir notification service with rest client
        # or kafka producer
        # RestClient.post("http://elixir-service/notify", { order_id: order_id, user_id: user_id }.to_json, { content_type: :json, accept: :json })
        # then elixir service will receive order data, send socket notification to user through phoenix channels to
        # nestjs and render form to make payment with transbank sdk
        # OrderConfirmationEmailJob.perform_later(order_id: order_id)
        Rails.logger.info("Order #{order_id} processed in Go service, email job enqueued")
      end
    end
  rescue RestClient::ExceptionWithResponse => e
    Rails.logger.error("Go service error: #{e.response}")
    raise
  rescue StandardError => e
    Rails.logger.error("Error calling Go service: #{e.message}")
    raise
  end
end
