# frozen_string_literal: true

require 'tmpdir'
require 'dropbox_api'
# require 'authentication_factory'

module BrowseEverything
  class Provider
    # The Provider class for interfacing with a drop box as a storage provider
    class DropBox < BrowseEverything::Provider
      # Determine whether or not a drop box key is a directory
      # @return [Boolean]
 
        def key
          byebug
          self.class.name.split(/::/).last.underscore
        end

        def self.folder?(gdrive_file)
        end
 
        def find_bytestream(id:)
        end
     

        def find_container(id:)
        end

        def root_container
        end
  
        private

          def build_container(dir)
          end
  
          def find_container_children(directory)
          end

          def build_bytestream(file)
          end

          def find_bytestream_children(directory)
          end

          def traverse_directory(directory)
          end
    end
  end
end



