# frozen_string_literal: true

module Api
  module V1
    module Payments
      class WebpayPlusController < ApplicationController
        skip_before_action :authenticate_user!, only: %i[commit]

        def retry
          payment = Payment.find_by!(id: params[:id], user_id: current_user.id)

          payment.with_lock do
            # Only allow retry for failed payments
            unless payment.status_failed?
              return render(json: { error: "Payment is not in failed status" }, status: :unprocessable_entity)
            end

            # Reset payment to pending
            payment.retry!

            # Create new Webpay transaction
            tx = WebpayClient.transaction
            create_tx = tx.create(
              payment.order_id.to_s,
              "user_#{payment.user_id}",
              payment.amount,
              Rails.application.routes.url_helpers.api_v1_payments_webpay_plus_commit_url
            )

            payment.update!(
              transaction_token: create_tx["token"],
              transaction_data: create_tx.to_json
            )

            # this response is used by frontend to redirect user to Webpay
            # {"url":"https://webpay3gint.transbank.cl/webpayserver/initTransaction","token":"01a"}
            render json: { url: create_tx["url"], token: create_tx["token"] }, status: :ok
          end
        rescue StandardError => e
          Rails.logger.error("Retry error: #{e.class} #{e.message}")
          render json: { error: "Internal error" }, status: :internal_server_error
        end

        def commit
          token = params[:token_ws]

          # Find payment first
          payment = Payment.find_by!(transaction_token: token)

          # Acquire lock to prevent concurrent processing
          payment.with_lock do
            # Idempotency: return early if already paid
            # Allow retries for failed payments
            if payment.status_paid?
              Rails.logger.info("Payment #{payment.id} already paid")
              return render(json: { message: "Payment already processed" }, status: :ok)
            end

            # Only call Webpay API if payment is still pending or failed
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
        rescue StandardError => e
          Rails.logger.error("Commit unexpected error: #{e.class} #{e.message}")
          render json: { error: "Internal error" }, status: :internal_server_error
        end
      end
    end
  end
end
