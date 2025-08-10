# frozen_string_literal: true

class ApplicationController < ActionController::API
  include HasDeviseWhitelist

  before_action :authenticate_user!
  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
  rescue_from ActionController::ParameterMissing, with: :render_parameter_missing

  def render_parameter_missing(exception)
    render json: {
      error: {
        code: 400,
        message: exception.message,
        type: "parameter_missing"
      }
    }, status: :bad_request
  end

  def render_not_found(exception)
    render json: {
      error: {
        code: 404,
        message: exception.message || "Resource not found",
        type: "not_found"
      }
    }, status: :not_found
  end
end
