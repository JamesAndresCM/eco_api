class CreateInventoryMovements < ActiveRecord::Migration[8.0]
  def change
    create_table :inventory_movements do |t|
      t.references :product, null: false, foreign_key: true
      t.string :type
      t.integer :quantity
      t.references :related_order, foreign_key: { to_table: :orders }
      t.timestamps
    end
  end
end
