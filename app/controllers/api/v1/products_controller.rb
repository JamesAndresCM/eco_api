# frozen_string_literal: true

module Api
  module V1
    class ProductsController < ApplicationController
      skip_before_action :authenticate_user!, only: %i[index show]
      before_action :set_product, only: :show

      def index
        products = ProductFilter.new(Product.all, filter_params).apply
        collection, meta = PaginationService.new(resource: products, page: params[:page], per_page: params[:per_page]).paginate
        render json: ProductSerializer.new(collection, meta: meta).serializable_hash, status: :ok
      end

      def show
        render json: ProductSerializer.new(@product).serializable_hash, status: :ok
      end

      private

      def set_product
        @product = Product.find(params[:id])
      end

      def filter_params
        params.permit(:search, :available, :min_price, :max_price)
      end
    end
  end
end
