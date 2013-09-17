module BrowseEverything
  class FileEntry
    attr_reader :location, :name, :size, :mtime, :type

    def initialize(location, name, size, mtime, type, container)
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
