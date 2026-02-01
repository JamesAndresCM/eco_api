# frozen_string_literal: true

module Payments
  class DecrementStockService < ApplicationService
    class InsufficientStockError < StandardError; end

    def initialize(payment:, response:)
      @payment = payment
      @response = response
      super()
    end

    def call
      # Quick check: avoid entering transaction if already paid
      return if payment.status_paid?

      ActiveRecord::Base.transaction do
        # Acquire pessimistic lock to prevent concurrent processing
        payment.lock!
        # Double-check after acquiring lock (state might have changed)
        return if payment.status_paid?

        order = payment.order
        decrement_stock!(order)
        payment.update!(
          status: :paid,
          paid_at: Time.current,
          transaction_reference: response[:authorization_code],
          transaction_data: response
        )
        order.update!(status: :completed)
      end
    end

    private

    attr_reader :payment, :response

    def decrement_stock!(order)
      products = Product.lock.where(id: order.items.pluck(:product_id)).index_by(&:id)
      order.items.includes(:product).each do |item|
        product = products[item.product_id]
        if product.stock_quantity < item.quantity
          raise InsufficientStockError, "Insufficient stock for product #{product.id}"
        end

        product.update!(stock_quantity: product.stock_quantity - item.quantity)
      end
    end
  end
end
