module BrowseEverything
  class FileEntry
    attr_reader :id, :location, :name, :size, :mtime, :type

    def initialize(id, location, name, size, mtime, container, type = nil)
      @id        = id
      @location  = location
      @name      = name
      @size      = size
      @mtime     = mtime
      @container = container
      @type      = type || (@container ? 'application/x-directory' : Rack::Mime.mime_type(File.extname(name)))
    end

    def relative_parent_path?
      name =~ /^\.\.?$/ ? true : false
    end

    def container?
      @container
    end
  end
end
