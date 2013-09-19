module BrowseEverything
  module Driver
    class Box < Base
      require 'ruby-box'

      def icon
        'file'
      end

      def validate_config
        unless config[:client_id]
          raise BrowseEverything::InitializationError, "Box driver requires a :client_id argument"
        end
        unless config[:client_secret]
          raise BrowseEverything::InitializationError, "Box driver requires a :client_secret argument"
        end
      end

      def contents(path='')
        box_client.root_folder.folders.each do |f|
         Rails.logger.info("@@@@@@@@@@#{f.inspect}")
          details(f)
        end
        result = []
        result
      end

      def details(f)

        BrowseEverything::FileEntry.new(
            "",#single use link
            f.description,
            f.size,
            f.mtime,
            f.directory? ? 'directory' : Rack::Mime.mime_type(File.extname(path)),
            f.directory?

        )
        Rails.logger.info("@@@@@@@@files: #{f.description}")
      end

      def auth_link
        callback = connector_response_url(config[:url_options])
        oauth_client.authorize_url(callback.to_s)
      end

      def authorized?
        #false
        @token.present?
      end

      def connect(code)
        @token = oauth_client.get_access_token(code).token
     #   @refresh_token = oauth_client.get_access_token(code).refresh_token
      end

      private
      def oauth_client
        session = RubyBox::Session.new({
                                           client_id: config[:client_id],
                                           client_secret: config[:client_secret]
                                       })

         session
        #todo error checking here
      end

      def box_client
        session = RubyBox::Session.new({
                                           client_id: config[:client_id],
                                           client_secret: config[:client_secret],
                                           access_token: @token
                                       })
        RubyBox::Client.new(session)
      end

    end

  end
end