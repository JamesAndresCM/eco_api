# frozen_string_literal: true

class GenerateRefreshTokenService < ApplicationService
  def initialize(user)
    super()
    @user = user
  end

  def call
    JWT.encode(payload, secret_key, "HS256")
  end

  private

  attr_reader :user

  def payload
    {
      sub: user.id,
      jti: SecureRandom.uuid,
      scp: "api_v1_user",
      exp: 1.day.from_now.to_i,
      iat: Time.current.to_i
    }
  end

  def secret_key
    Rails.application.credentials.devise_jwt_secret_key
  end
end
