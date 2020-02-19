# frozen_string_literal: true

module BrowseEverything
  module V1
    module Driver
      # The Driver class for interfacing with a file system as a storage provider
      class FileSystem < BrowseEverything::V1::Driver::Base
        # Determine whether or not a file system node is a directory
        # @return [Boolean]
        def self.directory?(file_system_node)
          File.directory?(file_system_node)
        end

        def find_bytestream(id:)
          return unless File.exist?(id)

          file = File.new(id)
          bytestream = build_bytestream(file)
          @resources = [bytestream]
          bytestream
        end

        def find_container(id:)
          return unless File.exist?(id) && self.class.directory?(id)

          directory = Dir.new(id)
          traverse_directory(directory)
          build_container(directory)
        end

        # Construct a FileEntry objects for a file-system resource
        # @param path [String] path to the file
        # @param display [String] display label for the resource
        # @return [BrowseEverything::FileEntry]
        def details(path, display = File.basename(path))
          return nil unless File.exist? path

          info = File::Stat.new(path)
          BrowseEverything::FileEntry.new(
            make_pathname(path),
            [key, path].join(':'),
            display,
            info.size,
            info.mtime,
            info.directory?
          )
        end

        private

          def build_container(dir)
            absolute_path = File.absolute_path(dir.path)
            uri = "file://#{absolute_path}"
            name = File.basename(absolute_path)

            bytestreams = @resources.select { |child| child.is_a?(Bytestream) }
            containers = @resources.select { |child| child.is_a?(Container) }

            Container.new(
              id: absolute_path,
              bytestreams: bytestreams,
              containers: containers,
              location: uri,
              name: name,
              mtime: File.mtime(absolute_path)
            )
          end

          def find_container_children(directory)
            parent_path = Pathname.new(directory.path)
            dir_children_paths = directory.children.select do |child|
              File.directory?(parent_path.join(child))
            end

            dir_children_paths.map do |path|
              dir = Dir.new(parent_path.join(path))
              build_container(dir)
            end
          end

          def build_bytestream(file)
            absolute_path = File.absolute_path(file.path)
            uri = "file://#{absolute_path}"
            name = File.basename(absolute_path)
            extname = File.extname(absolute_path)
            mime_type = Mime::Type.lookup_by_extension(extname)

            BrowseEverything::Bytestream.new(
              id: absolute_path,
              location: uri,
              name: name,
              size: file.size.to_i,
              mtime: file.mtime,
              media_type: mime_type,
              uri: uri
            )
          end

          def find_bytestream_children(directory)
            parent_path = Pathname.new(directory.path)
            file_children_paths = directory.children.select do |child|
              File.file?(parent_path.join(child))
            end

            file_children_paths.map do |path|
              file = File.new(parent_path.join(path))
              build_bytestream(file)
            end
          end

          def file_size(path)
            File.size(path).to_i
          rescue StandardError => e
            Rails.logger.error "Failed to find the file size for #{path}: #{e}"
            0
          end
      end
  end
  end
end
