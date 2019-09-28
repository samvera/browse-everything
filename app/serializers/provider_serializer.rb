# frozen_string_literal: true

class ProviderSerializer
  include FastJsonapi::ObjectSerializer
  attributes :id, :name

  link :authorization_url do |object|
    object.authorization_url
  end
end
