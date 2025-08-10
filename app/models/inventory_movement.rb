# frozen_string_literal: true

class InventoryMovement < ApplicationRecord
  belongs_to :product
  belongs_to :related_order, class_name: "Order", optional: true
end
