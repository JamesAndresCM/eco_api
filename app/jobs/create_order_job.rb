# frozen_string_literal: true

class CreateOrderJob < ApplicationJob
  queue_as :orders

  limits_concurrency to: 5, key: ->(user_id, _) { "user_orders_#{user_id}" }, duration: 5.minutes
  retry_on Kafka::OrderProducer::PublishError, wait: :exponentially_longer, attempts: 3

  def perform(user_id, order_params)
    @user_id = user_id
    return unless User.find_by(id: @user_id).present?

    create_order(order_params)
    Rails.logger.info("Order event published for user #{@user_id}")
  rescue StandardError => e
    Rails.logger.error("Error publishing order: #{e.message}")
    raise
  end

  private

  def create_order(order_params)
    Kafka::OrderProducer.publish(
      user_id: @user_id,
      items: order_params["items"]
    )
  end
end
