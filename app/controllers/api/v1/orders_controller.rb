# frozen_string_literal: true

module Api
  module V1
    class OrdersController < ApplicationController
      def index
        orders = current_user.orders.includes(order_items: :product).order(created_at: :desc)
        collection, meta = PaginationService.new(resource: orders, page: params[:page], per_page: params[:per_page]).paginate
        render json: OrderSerializer.new(collection, field_opts(meta: meta)).serializable_hash, status: :ok
      end

      def show
        order = current_user.orders.find(params[:id])
        render json: OrderSerializer.new(order, field_opts).serializable_hash, status: :ok
      end

      def create
        CreateOrderJob.perform_later(current_user.id, order_params.to_h)
        render json: { message: "Order is being processed" }, status: :ok
        #         order = Orders::CreateOrderService.call(user: current_user, items: order_params[:items])
        #         render json: { data: order_json(order) }, status: :created
        #       rescue Orders::CreateOrderService::ProductNotFoundError,
        #              Orders::CreateOrderService::InsufficientStockError,
        #              ArgumentError => e
        #         render json: { error: e.message }, status: :unprocessable_entity
        #       rescue Orders::CreateOrderService::OrderCreationError => e
        #         render json: { error: e.message }, status: :internal_server_error
      end

      private

      def order_params
        params.require(:order).permit(items: %i[product_id quantity])
      end

      def field_opts(attrs = {})
        {
          fields: {
            product: %i[id name description],
            order: %i[id status total_price total_items created_at updated_at items],
            order_item: %i[id product_id quantity price]
          },
          include: %i[items.product]
        }.merge(attrs)
      end
    end
  end
end
