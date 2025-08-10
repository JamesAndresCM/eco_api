class CreateCartItems < ActiveRecord::Migration[8.0]
  def change
    create_table :cart_items do |t|
      t.references :cart, null: false, foreign_key: true
      t.integer :quantity, null: false
      t.decimal :unit_price, precision: 12, scale: 2, null: false
      t.timestamps
    end
  end
end
