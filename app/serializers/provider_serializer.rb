# frozen_string_literal: true

class ProviderSerializer
  include FastJsonapi::ObjectSerializer
  attributes :id, :name

  link :authorization_url, &:authorization_url
end
