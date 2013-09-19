module BrowseEverything
  class FileEntry
    attr_reader :id, :location, :name, :size, :mtime, :type

    def initialize(id, location, name, size, mtime, type, container)
      @id        = id
      @location  = location
      @name      = name
      @size      = size
      @mtime     = mtime
      @type      = type
      @container = container
    end

    def container?
      @container
    end
  end
end
