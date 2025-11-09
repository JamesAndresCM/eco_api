class RemovePaymentIdFromOrder < ActiveRecord::Migration[8.0]
  def change
    remove_column :orders, :payment_id, :integer
  end
end
