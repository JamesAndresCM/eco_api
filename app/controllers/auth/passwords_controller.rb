# frozen_string_literal: true

module Auth
  class PasswordsController < Devise::PasswordsController
    respond_to :json

    def create
      user = User.find_by(email: resource_params[:email])
      if user.present?
        user.send_reset_password_instructions
        render json: { message: "Mail sent with instructions" }, status: :ok
      else
        render json: { error: "Mail not found" }, status: :not_found
      end
    end

    def update
      user = User.reset_password_by_token(resource_params)
      if user.errors.empty?
        render json: { message: "Password updated successfully" }, status: :ok
      else
        render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
      end
    end

    private

    def resource_params
      params.expect(user: %i[email password password_confirmation reset_password_token])
    end
  end
end
