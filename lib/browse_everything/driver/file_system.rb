# frozen_string_literal: true
module BrowseEverything
  class Driver
    # The Driver class for interfacing with a file system as a storage provider
    class FileSystem < BrowseEverything::Driver
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

      def root_container
        root_id = config[:home]
        find_container(id: root_id)
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

        def traverse_directory(directory)
          @resources = []
          @resources = find_container_children(directory)
          @resources += find_bytestream_children(directory)
        end
    end
  end
end
