# frozen_string_literal: true

module Auth
  class RegistrationsController < Devise::RegistrationsController
    include RackSessionsFix

    skip_before_action :authenticate_user!
    respond_to :json

    def respond_with(current_user, _opts = {})
      if resource.persisted?
        render json: { message: "Signed up successfully." }, status: :created
      else
        render json: {
          message: "User couldn't be created successfully. #{current_user.errors.full_messages.to_sentence}"
        }, status: :unprocessable_entity
      end
    end

    private

    def sign_up_params
      params.expect(user: %i[email password name])
    end
  end
end
