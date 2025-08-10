class AddExpToBlacklistedTokens < ActiveRecord::Migration[8.0]
  def change
    add_column :blacklisted_tokens, :exp, :datetime
  end
end
