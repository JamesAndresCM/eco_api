# frozen_string_literal: true

require "delegate"

class ProductDecorator < SimpleDelegator
  def available?
    stock_quantity.to_i.positive?
  end
end
