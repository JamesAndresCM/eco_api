class CreatePayments < ActiveRecord::Migration[8.0]
  def change
    create_table :payments do |t|
      t.references :order, null: false, foreign_key: true
      t.decimal :amount, precision: 12, scale: 2
      t.string :status
      t.string :method
      t.string :transaction_reference
      t.timestamps
    end
  end
end
