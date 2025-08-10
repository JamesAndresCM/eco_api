# frozen_string_literal: true

class InfoController < ApplicationController
  skip_before_action :authenticate_user!, only: :index

  def index
    render json: {
      api: "Ecommerce Service API",
      version: "1.0.0",
      description: "A Rails 8 API-only application with JWT authentication",
      endpoints: {
        authentication: {
          register: "POST /auth/register",
          login: "POST /auth/login",
          logout: "DELETE /auth/logout",
          refresh_token: "POST /auth/refresh_tokens",
          forgot_password: "POST /auth/forgot_password",
          change_password: "PATCH /auth/change_password"
        },
        users: {
          profile: "GET /api/v1/users/me"
        }
      },
      documentation: "See README.md for detailed API usage",
      health_check: "/up"
    }
  end
end
