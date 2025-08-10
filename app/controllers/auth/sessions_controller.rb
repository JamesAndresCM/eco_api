# frozen_string_literal: true

module Auth
  class SessionsController < Devise::SessionsController
    include RackSessionsFix

    skip_before_action :authenticate_user!
    respond_to :json

    def create
      user = User.find_by(email: sign_in_params[:email])

      if user&.valid_password?(sign_in_params[:password])
        sign_in(user)
        render json: UserSerializer.new(user).serialized_json, status: :ok
      else
        render json: { errors: "Invalid email or password" }, status: :unauthorized
      end
    end

    def respond_to_on_destroy
      auth_header = request.headers["Authorization"]&.split(" ")&.last
      if auth_header.present?
        token = auth_header.split(" ").last

        begin
          jwt_payload = JWT.decode(token, Rails.application.credentials.devise_jwt_secret_key!).first
          jti = jwt_payload["jti"]
          user_id = jwt_payload["sub"]
          current_user = User.find_by(id: user_id)

          if current_user && jti
            BlacklistedToken.create!(jti: jti, user: current_user, exp: Time.at(jwt_payload["exp"]))
            sign_out(current_user)

            render json: { message: "Logged out successfully" }, status: :ok
            return
          end
        rescue JWT::DecodeError => e
          Rails.logger.warn "JWT DecodeError: #{e.message}"
        rescue ActiveRecord::RecordInvalid => e
          Rails.logger.warn "RecordInvalid: Unable to blacklist token. #{e.message}"
        end
      end

      render json: { message: "Couldn't find an active session" }, status: :unauthorized
    end

    private

    def sign_in_params
      params.expect(user: %i[email password])
    end
  end
end
