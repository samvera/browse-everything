class SessionSerializer
  include FastJsonapi::ObjectSerializer
  attributes :provider_id, :authorization_ids

  link :authorization_url do |object|
    object.authorization_url
  end

  has_one :provider
  has_many :authorizations
end
