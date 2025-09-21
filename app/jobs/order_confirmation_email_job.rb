# frozen_string_literal: true

class OrderConfirmationEmailJob < ApplicationJob
  queue_as :emails

  limits_concurrency to: 10, key: ->(order_id) { "order_email_#{order_id}" }, duration: 2.minutes
  retry_on StandardError, wait: :exponentially_longer, attempts: 3
  discard_on ActiveRecord::RecordNotFound

  def perform(order_id:)
    order = Order.find(order_id)

    OrderMailer.order_created(order: order).deliver_now
    Rails.logger.info("Order confirmation email sent for order #{order_id}")
  rescue StandardError => e
    Rails.logger.error("Failed to send order confirmation email for order #{order_id}: #{e.message}")
    raise
  end
end
