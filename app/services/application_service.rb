# frozen_string_literal: true

class ApplicationService
  def self.call(*args, **kwargs)
    new(*args, **kwargs).call
  end

  private

  def initialize(*args, **kwargs)
    # Override in subclasses if needed
  end

  def call
    raise NoMethodError, "#{self.class} must implement #call"
  end
end
