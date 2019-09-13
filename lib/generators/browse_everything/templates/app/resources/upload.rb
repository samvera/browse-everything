# frozen_string_literal: true
class Upload < JSONAPI::Resource
  has_one :provider
end
