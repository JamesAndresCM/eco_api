# frozen_string_literal: true

class Product < ApplicationRecord
  has_many :cart_items
  has_many :order_items
  has_many :inventory_movements
end
