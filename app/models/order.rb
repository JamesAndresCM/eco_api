# frozen_string_literal: true

class Order < ApplicationRecord
  belongs_to :user
  has_many :order_items, dependent: :destroy
  has_one :payment
  has_many :inventory_movements, foreign_key: :related_order_id
  enum :status, { pending: 0, completed: 1, cancelled: 2 }, _prefix: true
end
