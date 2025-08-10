class CreateProducts < ActiveRecord::Migration[8.0]
  def change
    create_table :products do |t|
      t.string :name, null: false
      t.text :description
      t.decimal :price, precision: 12, scale: 2, null: false
      t.string :currency
      t.string :sku
      t.integer :stock_quantity, default: 0
      t.boolean :is_active, default: true
      t.timestamps
    end
  end
end
