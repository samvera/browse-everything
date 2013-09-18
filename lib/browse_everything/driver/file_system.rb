module BrowseEverything
  module Driver
    class FileSystem < Base

      def icon
        'file'
      end
      
      def validate_config
        unless config[:home]
          raise BrowseEverything::InitializationError, "FileSystem driver requires a :home argument"
        end
      end

      def contents(path='')
        relative_path = path.sub(%r{^[/.]+},'')
        real_path = File.join(config[:home], relative_path)
        result = []
        if relative_path.present?
          result << details('..')
        end
        if File.directory?(real_path)
          result += Dir[File.join(real_path,'*')].collect { |f| details(f) }
        else File.exists?(real_path)
          result += [details(real_path)]
        end
        result
      end

      def details(path)
        if File.exists?(path)
          info = File::Stat.new(path)
          BrowseEverything::FileEntry.new(
            "file://#{File.expand_path(File.join(config[:home],path))}",
            File.basename(path),
            info.size,
            info.mtime,
            info.directory? ? 'directory' : Rack::Mime.mime_type(File.extname(path)),
            info.directory?
          )
        else
          nil
        end
      end
    end

  end
end