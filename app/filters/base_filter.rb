# frozen_string_literal: true

class BaseFilter
  attr_accessor :default_collection, :search_params

  def initialize(default_collection, search_params = {})
    @default_collection = default_collection
    @search_params = search_params
  end

  def cast_bool(value)
    ActiveModel::Type::Boolean.new.cast(value)
  end

  def apply
    raise NoMethodError, "#{self.class} has not implemented method '#{__method__}'"
  end
end
