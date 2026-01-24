# frozen_string_literal: true

class Order < ApplicationRecord
  belongs_to :user
  has_many :items, class_name: "OrderItem", dependent: :destroy
  has_many :inventory_movements, foreign_key: :related_order_id
  enum :status, { pending: 0, completed: 1, cancelled: 2 }, prefix: true
  scope :total_quantity, -> { joins(:items).group("orders.id").sum("order_items.quantity") }
end
