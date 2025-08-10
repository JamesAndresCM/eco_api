# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_08_10_214517) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "blacklisted_tokens", force: :cascade do |t|
    t.string "jti"
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "exp"
    t.index ["jti"], name: "index_blacklisted_tokens_on_jti", unique: true
    t.index ["user_id"], name: "index_blacklisted_tokens_on_user_id"
  end

  create_table "cart_items", force: :cascade do |t|
    t.bigint "cart_id", null: false
    t.integer "quantity", null: false
    t.decimal "unit_price", precision: 12, scale: 2, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "product_id", null: false
    t.index ["cart_id"], name: "index_cart_items_on_cart_id"
    t.index ["product_id"], name: "index_cart_items_on_product_id"
  end

  create_table "carts", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.integer "status", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_carts_on_user_id"
  end

  create_table "events", force: :cascade do |t|
    t.string "aggregate_type"
    t.bigint "aggregate_id"
    t.string "event_type"
    t.jsonb "payload"
    t.datetime "published"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "inventory_movements", force: :cascade do |t|
    t.bigint "product_id", null: false
    t.string "type"
    t.integer "quantity"
    t.bigint "related_order_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["product_id"], name: "index_inventory_movements_on_product_id"
    t.index ["related_order_id"], name: "index_inventory_movements_on_related_order_id"
  end

  create_table "order_items", force: :cascade do |t|
    t.bigint "order_id", null: false
    t.bigint "product_id", null: false
    t.integer "quantity", null: false
    t.decimal "unit_price", precision: 12, scale: 2, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["order_id"], name: "index_order_items_on_order_id"
    t.index ["product_id"], name: "index_order_items_on_product_id"
  end

  create_table "orders", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.decimal "total_amount", precision: 12, scale: 2
    t.integer "status", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "payment_id"
    t.index ["payment_id"], name: "index_orders_on_payment_id"
    t.index ["user_id"], name: "index_orders_on_user_id"
  end

  create_table "payments", force: :cascade do |t|
    t.bigint "order_id", null: false
    t.decimal "amount", precision: 12, scale: 2
    t.string "status"
    t.string "method"
    t.string "transaction_reference"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["order_id"], name: "index_payments_on_order_id"
  end

  create_table "products", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.decimal "price", precision: 12, scale: 2, null: false
    t.string "currency"
    t.string "sku"
    t.integer "stock_quantity", default: 0
    t.boolean "is_active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "blacklisted_tokens", "users"
  add_foreign_key "cart_items", "carts"
  add_foreign_key "cart_items", "products"
  add_foreign_key "carts", "users"
  add_foreign_key "inventory_movements", "orders", column: "related_order_id"
  add_foreign_key "inventory_movements", "products"
  add_foreign_key "order_items", "orders"
  add_foreign_key "order_items", "products"
  add_foreign_key "orders", "payments"
  add_foreign_key "orders", "users"
  add_foreign_key "payments", "orders"
end
