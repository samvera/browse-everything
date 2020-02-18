# frozen_string_literal: true

module BrowseEverything
  class Container
    attr_accessor :id, :bytestreams, :bytestream_ids, :containers, :container_ids, :location, :name, :mtime

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
      @bytestream_ids = if @bytestreams.empty?
                          bytestream_ids
                        else
                          @bytestreams.map(&:id)
                        end

      @containers = containers
      @container_ids = if @containers.empty?
                         container_ids
                       else
                         @containers.map(&:id)
                       end

      @location = location
      @name = name
      @mtime = mtime
    end
  end
end
