class BaseSerializer
  include JSONAPI::Serializer

  def to_json
    Oj.dump(serializable_hash, mode: :compat)
  end

  alias_method :serialized_json, :to_json
end
