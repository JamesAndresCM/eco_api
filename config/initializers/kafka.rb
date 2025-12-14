# frozen_string_literal: true

KAFKA = Kafka.new(
  seed_brokers: [ENV.fetch("KAFKA_BROKERS", "localhost:9092")],
  client_id: "ecommerce-rails"
)
