# frozen_string_literal: true

module BrowseEverything
  module Driver
    class FileSystem < Base
      def icon
        'file'
      end

      def validate_config
        raise BrowseEverything::InitializationError, 'FileSystem driver requires a :home argument' if config[:home].blank?
      end

      def contents(path = '')
        real_path = File.join(config[:home], path)
        entries = if File.directory?(real_path)
                    make_directory_entry real_path
                  else
                    [details(real_path)]
                  end

        sort_entries(entries)
      end

      def link_for(path)
        full_path = File.expand_path(path)
        file_size = file_size(full_path)
        ["file://#{full_path}", { file_name: File.basename(path), file_size: file_size }]
      end

      def authorized?
        true
      end

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

        def make_directory_entry(real_path)
          entries = []
          entries + Dir[File.join(real_path, '*')].collect { |f| details(f) }
        end

        def sort_entries(entries)
          entries.sort do |a, b|
            if b.container?
              a.container? ? a.name.downcase <=> b.name.downcase : 1
            else
              a.container? ? -1 : a.name.downcase <=> b.name.downcase
            end
          end
        end

        def make_pathname(path)
          Pathname.new(File.expand_path(path)).relative_path_from(Pathname.new(config[:home]))
        end

        def file_size(path)
          File.size(path).to_i
        rescue StandardError => error
          Rails.logger.error "Failed to find the file size for #{path}: #{error}"
          0
        end
    end
  end
end
