# frozen_string_literal: true

class DecodeRefreshTokenService < ApplicationService
  def initialize(token)
    super()
    @token = token
  end

  def call
    validate_token_not_blacklisted
    user = find_user_from_token
    revoke_token
    user
  end

  private

  attr_reader :token

  def validate_token_not_blacklisted
    blacklisted_token = BlacklistedToken.find_by(jti: payload["jti"])
    raise JWT::DecodeError, "Token has been blacklisted" if blacklisted_token.present?
  end

  def find_user_from_token
    User.find(payload["sub"])
  end

  def revoke_token
    BlacklistedToken.create!(
      jti: payload["jti"],
      user: find_user_from_token,
      exp: Time.at(payload["exp"] || 1.day.from_now.to_i)
    )
  end

  def payload
    @payload ||= JWT.decode(token, secret_key, true, algorithm: "HS256").first
  end

  def secret_key
    Rails.application.credentials.devise_jwt_secret_key
  end
end
