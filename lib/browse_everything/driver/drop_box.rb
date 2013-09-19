require 'dropbox_sdk'

module BrowseEverything
  module Driver
    class DropBox < Base

      def icon
        'dropbox'
      end
      
      def validate_config
        unless [:app_key,:app_secret].all? { |key| config[key].present? }
          raise BrowseEverything::InitializationError, "DropBox driver requires :app_key and :app_secret"
        end
      end

      def contents(path='')
        client.metadata(path)['contents'].collect do |info|
          path = info['path']
          BrowseEverything::FileEntry.new(
            [self.key,path].join(':'),
            File.basename(path),
            info['size'],
            Time.parse(info['modified']),
            info['is_dir'] ? 'directory' : Rack::Mime.mime_type(File.extname(path)),
            info['is_dir']
          )
        end
      end

      def link_for(path)
        client.media(path)['url']
      end

      def details(path)
        contents(path).first
      end

      def auth_link
        [ auth_flow.start('drop_box'), @csrf ]
      end

      def connect(params,data)
        @csrf = data
        @token, user, state = auth_flow.finish(params)
        @token
      end

      def authorized?
        token.present?
      end

      private
      def auth_flow
        @csrf ||= {}
        DropboxOAuth2Flow.new(config[:app_key], config[:app_secret], connector_response_url(config[:url_options]).to_s,@csrf,:token)
      end

      def client
        DropboxClient.new(token)
      end
    end

  end
end