# frozen_string_literal: true

class PaginationService
  DEFAULT_PAGE = 1
  PER_PAGE = 20
  MAX_PER_PAGE = 100

  def initialize(params)
    @resource = params[:resource] || []
    @page = params[:page].to_i.abs.positive? ? params[:page].to_i.abs : DEFAULT_PAGE
    @per_page = validate_per_page(params[:per_page])
  end

  def paginate
    total_elements = total_size.respond_to?(:to_int) ? total_size : total_size&.size
    data = if @resource.respond_to?(:offset)
             @resource.offset((@page - 1) * @per_page).limit(@per_page)
           else
             @resource[(@page - 1) * @per_page, @per_page] || []
           end
    meta = {
      page: @page,
      per_page: @per_page,
      total_elements: total_elements
    }
    [data, meta]
  end

  private

  def validate_per_page(per_page)
    per_page = per_page.to_i.abs
    per_page = PER_PAGE unless per_page.positive?
    per_page = MAX_PER_PAGE if per_page > MAX_PER_PAGE
    per_page
  end

  def total_size
    @total_size ||= @resource.size
  end
end
