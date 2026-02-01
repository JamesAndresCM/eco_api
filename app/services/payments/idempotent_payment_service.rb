# frozen_string_literal: true

module Payments
  # Service to handle idempotent payment creation
  # Ensures that duplicate payment requests with the same idempotency key
  # do not create multiple payment records
  #
  # The idempotency key is automatically generated from order_id and user_id
  # unless explicitly provided
  class IdempotentPaymentService < ApplicationService
    class DuplicatePaymentError < StandardError; end

    def initialize(order_id:, user_id:, amount:, idempotency_key: nil)
      @order_id = order_id
      @user_id = user_id
      @amount = amount
      @idempotency_key = idempotency_key || generate_idempotency_key
      super()
    end

    def call
      # Try to find existing payment with the same idempotency key
      existing_payment = Payment.find_by(idempotency_key: idempotency_key)
      return existing_payment if existing_payment

      # Create payment with idempotency key in a transaction
      create_payment_safely
    rescue ActiveRecord::RecordNotUnique
      # Handle race condition: another process created the payment
      # between our find_by and create!
      Payment.find_by!(idempotency_key: idempotency_key)
    end

    private

    attr_reader :idempotency_key, :order_id, :user_id, :amount

    def generate_idempotency_key
      Digest::SHA256.hexdigest("payment:order:#{order_id}:user:#{user_id}")
    end

    def create_payment_safely
      Payment.create!(
        idempotency_key: idempotency_key,
        order_id: order_id,
        user_id: user_id,
        amount: amount,
        status: :pending
      )
    end
  end
end
