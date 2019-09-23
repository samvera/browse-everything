
# frozen_string_literal: true
module BrowseEverything
  class Container
    attr_accessor :id, :bytestream_ids, :container_ids, :location, :name, :mtime

    # Constructor
    # @param id
    # @param bytestream_ids
    # @param container_ids
    # @param location
    # @param name
    # @param mtime
    def initialize(id:, bytestreams: [], bytestream_ids: [], containers: [], container_ids: [], location:, name:, mtime:)
      @id = id

      @bytestreams = bytestreams
      if @bytestreams.empty?
        @bytestream_ids = bytestream_ids
      else
        @bytestream_ids = @bytestreams.map(&:id)
      end

      @containers = containers
      if @containers.empty?
        @container_ids = container_ids
      else
        @container_ids = @containers.map(&:id)
      end

      @location = location
      @name = name
      @mtime = mtime
    end
  end
end
