# frozen_string_literal: true

module Kafka
  class OrderProducer
    class PublishError < StandardError; end

    TOPIC = "orders.create"

    def self.publish(user_id:, items:)
      payload = {
        user_id: user_id,
        items: items,
        requested_at: Time.current.iso8601
      }

      KAFKA.deliver_message(
        payload.to_json,
        topic: TOPIC,
        key: user_id.to_s
      )
    rescue ::Kafka::Error => e
      Rails.logger.error("Kafka publish failed: #{e.message}")
      raise PublishError, e.message
    end
  end
end
