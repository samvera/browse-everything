
# frozen_string_literal: true
class ProviderSerializer
  include FastJsonapi::ObjectSerializer
  attributes :id

  link :authorization_url, &:authorization_url
end
