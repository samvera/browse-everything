module BrowseEverything
  module Driver
    class FileSystem < Base
      def icon
        'file'
      end

      def validate_config
        return if config[:home].present?
        raise BrowseEverything::InitializationError, 'FileSystem driver requires a :home argument'
      end

      def contents(path = '')
        relative_path = path.sub(%r{^[\/.]+}, '')
        real_path = File.join(config[:home], relative_path)
        entries = if File.directory?(real_path)
                    make_directory_entry(relative_path, real_path)
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
        return nil unless File.exist?(path)
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

        def make_directory_entry(relative_path, real_path)
          entries = []
          if relative_path.present?
            entries << details(File.expand_path('..', real_path), '..')
          end
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
        rescue
          0
        end
    end
  end
end
