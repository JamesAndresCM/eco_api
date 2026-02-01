# frozen_string_literal: true

module Api
  module V1
    module Payments
      class WebpayPlusController < ApplicationController
        skip_before_action :authenticate_user!, only: %i[commit]

        def commit
          token = params[:token_ws]

          # Find payment first
          payment = Payment.find_by!(transaction_token: token)

          # Acquire lock to prevent concurrent processing
          payment.with_lock do
            # Idempotency: return early if already processed
            if payment.status.in?(%w[paid failed])
              Rails.logger.info("Payment #{payment.id} already processed with status: #{payment.status}")
              return render(json: { message: "Payment already processed" }, status: :ok)
            end

            # Only call Webpay API if payment is still pending
            tx = WebpayClient.transaction
            response = tx.commit(token)
            response.symbolize_keys!

            if response[:status] == "AUTHORIZED"
              ::Payments::DecrementStockService.call(payment: payment, response: response)
              render json: { message: "Payment successful!" }, status: :ok
            else
              payment.update!(status: :failed, transaction_data: response)
              render json: { message: "Payment not authorized" }, status: :unprocessable_entity
            end
          end
        rescue ::Payments::DecrementStockService::InsufficientStockError => e
          Rails.logger.warn("Commit aborted: #{e.message}")
          render json: { error: "Insufficient stock" }, status: :unprocessable_entity
        rescue ActiveRecord::RecordNotFound => e
          Rails.logger.error("Commit error: #{e.message}")
          render json: { error: e.message }, status: :not_found
        rescue StandardError => e
          Rails.logger.error("Commit unexpected error: #{e.class} #{e.message}")
          render json: { error: "Internal error" }, status: :internal_server_error
        end
      end
    end
  end
end
