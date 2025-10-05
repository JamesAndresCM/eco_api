class AddExtraFieldsToPayment < ActiveRecord::Migration[8.0]
  def change
    add_column :payments, :transaction_data, :jsonb, default: {}
    add_column :payments, :transaction_token, :string
    add_column :payments, :paid_at, :datetime
    add_column :payments, :user_id, :bigint
    add_index :payments, :user_id
    add_foreign_key :payments, :users, column: :user_id
  end
end
