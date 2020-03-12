# frozen_string_literal: true

module BrowseEverything
  class ContainerSerializer
    include FastJsonapi::ObjectSerializer
    attributes :id, :name, :mtime

    has_many :bytestreams
    has_many :containers
  end
end
