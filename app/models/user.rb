# frozen_string_literal: true

class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :jwt_authenticatable,
         jwt_revocation_strategy: BlacklistedToken
  validates :name, presence: true

  def self.decode_refresh_token(token)
    Auth::DecodeRefreshTokenService.call(token)
  end

  def generate_refresh_token
    Auth::GenerateRefreshTokenService.call(self)
  end

  def jwt_payload(version: :v1)
    {
      "sub" => id,
      "scp" => "api_#{version}_user"
    }
  end
end
