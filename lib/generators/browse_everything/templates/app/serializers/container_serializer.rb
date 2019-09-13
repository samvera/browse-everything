# frozen_string_literal: true
class ContainerSerializer
  include FastJsonapi::ObjectSerializer
  attributes :id

  has_many :bytestreams
  has_many :containers
end
