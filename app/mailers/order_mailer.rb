# frozen_string_literal: true

class OrderMailer < ApplicationMailer
  def order_created(order:)
    @order = order
    @user = order.user
    @order_items = order.items.includes(:product)
    @total_items = @order_items.sum(:quantity)

    mail(
      to: @user.email,
      subject: "Order Confirmation ##{@order.id} - Your order has been created!"
    )
  end
end
