class RemoveMethodToPayment < ActiveRecord::Migration[8.0]
  def change
    remove_column :payments, :method, :string
  end
end
