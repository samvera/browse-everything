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
          {
            :name      => File.basename(path),
            :container => info.directory?,
            :mtime     => info.mtime,
            :size      => info.size,
            :mime_type => Rack::Mime.mime_type(File.extname(path))
          }
        else
          {}
        end
      end
    end

  end
end