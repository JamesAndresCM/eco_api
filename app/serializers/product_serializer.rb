# frozen_string_literal: true

class ProductSerializer < BaseSerializer
  attributes :id, :name, :description, :stock_quantity

  attribute :price do |object, _params|
    object.price.to_f
  end

  attribute :available do |object, _params|
    ProductDecorator.new(object).available?
  end
  build_timestamps
end
