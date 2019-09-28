# frozen_string_literal: true
class ContainerSerializer
  include FastJsonapi::ObjectSerializer
  attributes :id, :name, :mtime

  has_many :bytestreams, serializer: BytestreamSerializer
  has_many :containers, serializer: ContainerSerializer
end
