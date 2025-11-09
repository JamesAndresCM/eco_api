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
      ActiveRecord::Base.transaction do
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
      order.items.includes(:product).each do |item|
        product = Product.lock.find(item.product_id)
        if product.stock_quantity < item.quantity
          raise InsufficientStockError, "Insufficient stock for product #{product.id}"
        end

        product.update!(stock_quantity: product.stock_quantity - item.quantity)
      end
    end
  end
end
