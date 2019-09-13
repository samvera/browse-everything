# frozen_string_literal: true
class SessionSerializer
  include FastJsonapi::ObjectSerializer
  attributes :provider_id, :authorization_ids

  link :authorization_url, &:authorization_url

  has_one :provider
  has_many :authorizations
end
