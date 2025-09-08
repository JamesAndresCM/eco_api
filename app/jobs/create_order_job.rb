# frozen_string_literal: true

class CreateOrderJob < ApplicationJob
  queue_as :default

  def perform(user_id, order_params)
    user = User.find(user_id)
    order = user.orders.create!(order_params)
    # Additional logic for processing the order can be added here
    Rails.logger.info("Order #{order.id} created for User #{user.id}")
  rescue ActiveRecord::RecordNotFound => e
    Rails.logger.error("User not found: #{e.message}")
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error("Order creation failed: #{e.record.errors.full_messages.join(', ')}")
  end
end
