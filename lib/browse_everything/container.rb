
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
    def initialize(id:, bytestream_ids: [], container_ids: [], location:, name:, mtime:)
      @id = id
      @bytestream_ids = bytestream_ids
      @container_ids = container_ids
      @location = location
      @name = name
      @mtime = mtime
    end
  end
end
