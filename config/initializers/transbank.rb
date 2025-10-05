# frozen_string_literal: true

require "transbank/sdk"

WEBPAY_ENVIRONMENT = if Rails.env.production?
                       :production
                     else
                       :integration
                     end

WEBPAY_COMMERCE_CODE = if WEBPAY_ENVIRONMENT == :integration
                         Transbank::Common::IntegrationCommerceCodes::WEBPAY_PLUS
                       else
                         ENV.fetch("WEBPAY_COMMERCE_CODE")
                       end

WEBPAY_API_KEY = if WEBPAY_ENVIRONMENT == :integration
                   Transbank::Common::IntegrationApiKeys::WEBPAY
                 else
                   ENV.fetch("WEBPAY_API_KEY")
                 end

WEBPAY_OPTIONS = Transbank::Webpay::Options.new(
  WEBPAY_COMMERCE_CODE,
  WEBPAY_API_KEY,
  WEBPAY_ENVIRONMENT
)

module WebpayClient
  def self.transaction
    Transbank::Webpay::WebpayPlus::Transaction.new(WEBPAY_OPTIONS)
  end
end
