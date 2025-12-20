# frozen_string_literal: true

class OrdersFailedConsumer < ApplicationConsumer
  def consume
    messages.each do |message|
      process_failure(message.payload)
    rescue StandardError => e
      Rails.logger.error("Error processing orders.failed message: #{e.message}")
    end
  end

  private

  def process_failure(payload)
    user_id = payload["user_id"]
    error   = payload["error"]
    Rails.logger.error("Order failed for user #{user_id}: #{error}")
  end
end
