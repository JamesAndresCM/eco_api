# frozen_string_literal: true

class ApplicationController < ActionController::API
  include HasDeviseWhitelist

  before_action :authenticate_user!, unless: :skip_authentication?
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

  def render_not_found(exception = nil)
    render json: {
      error: {
        code: 404,
        message: exception&.message || "Resource not found",
        type: "not_found"
      }
    }, status: :not_found
  end

  private

  def skip_authentication?
    jobs_dashboard? || action_name == "render_not_found"
  end

  def jobs_dashboard?
    request.path.start_with?("/jobs")
  end
end
