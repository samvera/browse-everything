# frozen_string_literal: true

class SessionSerializer
  include FastJsonapi::ObjectSerializer
  attributes :provider_id, :authorization_ids

  has_one :provider
  has_many :authorizations
end
