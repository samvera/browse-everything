module BrowseEverything
  module Driver
    class SkyDrive < Base

      require 'skydrive'

      def icon
        'windows'
      end
      
      def validate_config
        unless config[:client_id]
          raise BrowseEverything::InitializationError, "SkyDrive driver requires a :client_id argument"
        end
        unless config[:client_secret]
          raise BrowseEverything::InitializationError, "SkyDrive driver requires a :client_secret argument"
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

      def auth_link(opts={})
        callback = connector_response_url(opts)
        oauth_client = Skydrive::Oauth::Client.new(config[:client_id], config[:client_secret], callback.to_s,"wl.skydrive")
        #todo error checking here
        oauth_client.authorize_url
      end

    end

  end
end