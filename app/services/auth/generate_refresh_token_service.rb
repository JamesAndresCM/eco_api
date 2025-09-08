# frozen_string_literal: true

module Auth
  class GenerateRefreshTokenService < ApplicationService
    EXP_TIME = 1.day.from_now.to_i
    ALGORITHM = "HS256"
    IAT = Time.current.to_i

    def initialize(user)
      super()
      @user = user
    end

    def call
      JWT.encode(payload, secret_key, ALGORITHM)
    end

    private

    attr_reader :user

    def payload(version: :v1)
      {
        sub: user.id,
        jti: SecureRandom.uuid,
        scp: "api_#{version}_user",
        exp: EXP_TIME,
        iat: IAT
      }
    end

    def secret_key
      Rails.application.credentials.devise_jwt_secret_key
    end
  end
end
