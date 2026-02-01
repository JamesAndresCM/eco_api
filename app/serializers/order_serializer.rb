# frozen_string_literal: true

class OrderSerializer < BaseSerializer
  attributes :id, :status

  attribute :total_price do |object, _params|
    object.total_amount.to_f
  end

  attribute :total_items do |object, params|
    params.dig(:total_quantity, object.id) || 0
  end

  attribute :payment_id do |object, params|
    params.dig(:payment_id, object.id)
  end

  has_many :items, serializer: ItemSerializer
  build_timestamps
end
