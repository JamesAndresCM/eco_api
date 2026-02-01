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

      Karafka.producer.produce_sync(
        topic: TOPIC,
        payload: payload.to_json,
        key: user_id.to_s
      )

      Rails.logger.info("📤 Order event published to #{TOPIC} for user #{user_id}")
    rescue StandardError => e
      Rails.logger.error("Karafka publish failed: #{e.message}")
      raise PublishError, e.message
    end
  end
end
