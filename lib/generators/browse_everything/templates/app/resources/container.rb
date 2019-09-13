# frozen_string_literal: true
class Container < JSONAPI::Resource
  attributes :uri

  has_many :containers
  has_many :bytestreams
end
