require "rails"
require "browse_everything/version"
require "browse_everything/engine"

module BrowseEverything
  class InitializationError < RuntimeError; end

  autoload :Browser,   'browse_everything/browser'
  autoload :FileEntry, 'browse_everything/file_entry'
  module Driver
    autoload :Base,       'browse_everything/driver/base'
    autoload :FileSystem, 'browse_everything/driver/file_system'
    autoload :SkyDrive, 'browse_everything/driver/sky_drive'
    autoload :Box, 'browse_everything/driver/box'
  end
end
