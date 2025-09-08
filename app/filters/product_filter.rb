# frozen_string_literal: true

class ProductFilter < BaseFilter
  def apply
    default_collection.then { |collection| by_search(collection) }
                      .then { |collection| by_availability(collection) }
                      .then { |collection| by_min_price(collection) }
                      .then { |collection| by_max_price(collection) }
  end

  private

  def by_search(scope)
    term = search_params[:search].to_s.strip
    return scope if term.empty?

    q = "%#{term}%"
    scope.where("name ILIKE :q OR description ILIKE :q", q: q)
  end

  def by_availability(scope)
    return scope unless search_params.key?(:available)

    available = cast_bool(search_params[:available])
    available ? scope.where("stock_quantity > 0") : scope.where("stock_quantity <= 0")
  end

  def by_min_price(scope)
    return scope unless search_params[:min_price].present?

    scope.where("price >= ?", search_params[:min_price])
  end

  def by_max_price(scope)
    return scope unless search_params[:max_price].present?

    scope.where("price <= ?", search_params[:max_price])
  end
end
