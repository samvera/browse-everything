
class ProviderSerializer
  include FastJsonapi::ObjectSerializer
  attributes :id

  link :authorization_url do |object|
    object.authorization_url
  end
end
