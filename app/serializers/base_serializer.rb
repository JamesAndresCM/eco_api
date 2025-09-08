# frozen_string_literal: true

class BaseSerializer
  include HasFormatDate
  include JSONAPI::Serializer

  def to_json(*_args)
    Oj.dump(serializable_hash, mode: :compat)
  end

  alias serialized_json to_json
end
