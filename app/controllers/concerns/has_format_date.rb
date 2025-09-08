# frozen_string_literal: true

module HasFormatDate
  extend ActiveSupport::Concern

  class_methods do
    def build_timestamps
      %i[
        created_at
        updated_at
      ].each do |attr|
        attribute attr do |obj|
          obj.send(attr).try(:iso8601)
        end
      end
    end
  end
end
