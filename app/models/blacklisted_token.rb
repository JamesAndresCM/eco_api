# frozen_string_literal: true

class BlacklistedToken < ApplicationRecord
  include Devise::JWT::RevocationStrategies::Denylist

  self.table_name = "blacklisted_tokens"
  belongs_to :user
  validates :jti, presence: true, uniqueness: true
end
