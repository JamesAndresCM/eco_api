# frozen_string_literal: true

class ApplicationService
  def self.call(...) = new(...).call
  def initialize(...)
    super
  end

  def call
    raise NoMethodError, "#{self.class.name} must implement #call"
  end
end
