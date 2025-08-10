class CreateBlacklistedTokens < ActiveRecord::Migration[8.0]
  def change
    create_table :blacklisted_tokens do |t|
      t.string :jti
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
    add_index :blacklisted_tokens, :jti, unique: true
  end
end
