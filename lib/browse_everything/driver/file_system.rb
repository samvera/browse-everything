module BrowseEverything
  module Driver
    class FileSystem < Base

      def validate_config
        unless config[:home]
          raise BrowseEverything::InitializationError, "FileSystem driver requires a :home argument"
        end
      end

      def contents(path='')
        real_path = File.join(config[:home], path.sub(%r{^[/.]+},''))
        if File.directory?(real_path)
          Dir[File.join(real_path,'*')].collect { |f| details(f) }
        else File.exists?(real_path)
          [details(real_path)]
        end
      end

      def details(path)
        if File.exists?(path)
          info = File::Stat.new(path)
          BrowseEverything::FileEntry.new(
            "file://#{File.expand_path(File.join(config[:home],path))}",
            File.basename(path),
            info.size,
            info.mtime,
            Rack::Mime.mime_type(File.extname(path)),
            info.directory?
          )
        else
          nil
        end
      end
    end

  end
end