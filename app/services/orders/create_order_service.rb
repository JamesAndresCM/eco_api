# frozen_string_literal: true

module Orders
  class CreateOrderService < ApplicationService
    class OrderCreationError < StandardError; end
    class InsufficientStockError < StandardError; end
    class ProductNotFoundError < StandardError; end

    def initialize(user:, items:, status: "pending")
      super()
      @user = user
      @items = items || []
      @status = status
    end

    def call
      validate_items!

      ActiveRecord::Base.transaction do
        create_order!
        add_items!
        recalc_total!
        decrement_stock!
        order
      end
    rescue ActiveRecord::RecordInvalid => e
      raise OrderCreationError, e.message
    end

    private

    attr_reader :user, :items, :status
    attr_accessor :order

    def validate_items!
      raise ArgumentError, "Items cannot be empty" if items.empty?
      items.each { |item| validate_item!(item) }
    end

    def validate_item!(item)
      required = %w[product_id quantity]
      missing = required - item.keys.map(&:to_s)
      raise ArgumentError, "Missing required keys: #{missing.join(', ')}" if missing.any?

      qty = Integer(item[:quantity] || item["quantity"])
      raise ArgumentError, "Quantity must be greater than 0" if qty <= 0

      product = Product.find(item[:product_id] || item["product_id"])
      raise InsufficientStockError, "Insufficient stock for #{product.name}" if product.stock < qty
    rescue ActiveRecord::RecordNotFound
      id = item[:product_id] || item["product_id"]
      raise ProductNotFoundError, "Product with ID #{id} not found"
    end

    def create_order!
      self.order = Order.create!(user:, status:, total: 0)
    end

    def add_items!
      items.each do |item|
        product = Product.find(item[:product_id] || item["product_id"])
        qty = Integer(item[:quantity] || item["quantity"])

        OrderItem.create!(
          order:,
          product:,
          quantity: qty,
          price: product.price
        )
      end
    end

    def recalc_total!
      total = order.order_items.sum("price * quantity")
      order.update!(total:)
    end

    def decrement_stock!
      order.order_items.includes(:product).find_each do |item|
        product = item.product
        product.update!(stock: product.stock - item.quantity)
      end
    end
  end
end