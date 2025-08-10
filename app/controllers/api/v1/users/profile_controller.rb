# frozen_string_literal: true

module Api
  module V1
    module Users
      class ProfileController < ApplicationController
        def me
          render json: {
            message: "Hello #{current_user.name || current_user.email}, you are authenticated!"
          }, status: :ok
        end
      end
    end
  end
end
