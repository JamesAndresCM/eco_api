# frozen_string_literal: true

module Auth
  class RefreshTokensController < ApplicationController
    include RackSessionsFix
    include Devise::Controllers::Helpers

    rescue_from JWT::DecodeError, with: :handle_decode_error

    skip_before_action :authenticate_user!

    def create
      user = decode_refresh_token(refresh_token_params[:refresh_token])
      generate_refresh_token(user)
      sign_in(user)
      render json: { message: "Token refreshed successfully" }, status: :ok
    end

    private

    def generate_refresh_token(user)
      token = user.generate_refresh_token
      response.headers["Authorization"] = "Bearer #{token}"
    end

    def decode_refresh_token(token)
      User.decode_refresh_token(token)
    end

    def refresh_token_params
      params.expect(user: [:refresh_token])
    end

    def handle_decode_error
      render json: { errors: "Invalid refresh token" }, status: :unauthorized
    end
  end
end
