# frozen_string_literal: true

class ItemSerializer < BaseSerializer
  attributes :id, :quantity

  attribute :price do |object, _params|
    object.unit_price.to_f
  end

  belongs_to :product, serializer: ProductSerializer
  build_timestamps
end
