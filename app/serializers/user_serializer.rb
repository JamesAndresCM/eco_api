class UserSerializer < BaseSerializer
  include JSONAPI::Serializer
  attributes :name
end
