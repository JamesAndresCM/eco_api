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
    DecodeRefreshTokenService.call(token)
  end

  def generate_refresh_token
    GenerateRefreshTokenService.call(self)
  end

  def jwt_payload
    {
      "sub" => id,
      "scp" => "api_v1_user" # tu scope personalizado
      # Puedes agregar más claims si quieres
    }
  end
end
