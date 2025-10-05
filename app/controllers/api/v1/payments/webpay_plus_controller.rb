# frozen_string_literal: true

module Api
  module V1
    module Payments
      class WebpayPlusController < ApplicationController
        skip_before_action :authenticate_user!, only: %i[commit]

        def commit
          token = params[:token_ws]

          tx = WebpayClient.transaction
          response = tx.commit(token)
          response.symbolize_keys!

          payment = Payment.find_by!(transaction_token: token)
          if response[:status] == "AUTHORIZED"
            payment.update(status: "paid", paid_at: Time.current, transaction_reference: response[:authorization_code])
            render json: { message: "Payment successful!" }, status: :ok
          else
            payment.update(status: "failed", transaction_data: response)
            render json: { message: "Payment not authorized" }, status: :unprocessable_entity
          end
        end
      end
    end
  end
end
