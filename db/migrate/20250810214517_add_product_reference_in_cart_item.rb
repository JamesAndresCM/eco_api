class AddProductReferenceInCartItem < ActiveRecord::Migration[8.0]
  def change
    add_reference :cart_items, :product, null: false, foreign_key: true
  end
end
