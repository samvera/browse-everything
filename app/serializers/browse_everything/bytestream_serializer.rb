# frozen_string_literal: true

module BrowseEverything
  class BytestreamSerializer
    include FastJsonapi::ObjectSerializer
    attributes :location, :name, :size, :mtime, :media_type, :uri
  end
end
