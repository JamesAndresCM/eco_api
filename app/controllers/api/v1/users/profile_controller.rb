# frozen_string_literal: true

module Api
  module V1
    module Users
      class ProfileController < ApplicationController
        def me
          render json: {
            status: {
              code: 200,
              message: "Hello #{current_user.name || current_user.email}, you are authenticated!",
              data: {
                user: UserSerializer.new(current_user).serializable_hash[:data][:attributes]
              }
            }
          }, status: :ok
        end
      end
    end
  end
end
