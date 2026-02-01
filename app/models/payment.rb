# frozen_string_literal: true

class Payment < ApplicationRecord
  belongs_to :order
  belongs_to :user
  enum :status, { pending: "pending", paid: "paid", failed: "failed" }, prefix: true
  validates :amount, presence: true
  validates :idempotency_key, presence: true, uniqueness: true
  validates :transaction_token, uniqueness: true, allow_nil: true

  def retry!
    update!(status: :pending, transaction_token: nil, transaction_data: nil)
  end
end
