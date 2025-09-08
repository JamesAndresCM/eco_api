# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# frozen_string_literal: true

if Rails.env.development?
  puts "Clearing existing data..."
  OrderItem.destroy_all
  Order.destroy_all
  Product.destroy_all
end

puts "Creating users..."
users = [
  { name: "John Doe", email: "john@example.com", password: "password123" },
  { name: "Jane Smith", email: "jane@example.com", password: "password123" }
].map { |attrs| User.create!(attrs) }

puts "Creating products..."
products = [
  { name: "Wireless Headphones", description: "Noise cancelling",   price: 199.99, stock_quantity: 50 },
  { name: "Smartphone",          description: "Latest model",       price: 899.99, stock_quantity: 25 },
  { name: "Laptop",              description: "Professional grade", price: 1299.99, stock_quantity: 15 },
  { name: "Coffee Maker",        description: "Programmable",       price: 149.99, stock_quantity: 30 }
].map { |attrs| Product.create!(attrs) }

puts "Creating sample orders..."
3.times do
  user = users.sample
  order = Order.create!(user: user, status: "pending", total_amount: 0)
  total = 0

  rand(1..2).times do
    product = products.sample
    qty = rand(1..3)
    OrderItem.create!(order: order, product: product, quantity: qty, unit_price: product.price)
    total += product.price * qty
  end

  order.update!(total_amount: total)
end

puts "Done. Users: #{User.count}, Products: #{Product.count}, Orders: #{Order.count}, OrderItems: #{OrderItem.count}"
