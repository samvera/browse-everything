module BrowseEverything
  module Driver
    class Box < Base
      require 'ruby-box'

      def icon
        'cloud'
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
        path.sub!(/^[\/.]+/,'')
        result = []
        unless path.empty?
          result << BrowseEverything::FileEntry.new(
              Pathname(path).join('..'),
              '', '..', 0, Time.now, true
          )
        end
        folder = path.empty? ? box_client.root_folder : box_client.folder(path)
        result += folder.items.collect do |f|
        BrowseEverything::FileEntry.new(
            File.join(path,f.name),#id here
            "#{self.key}:#{File.join(path,f.name)}",#single use link
            f.name,
            f.size,
            f.created_at,
            f.type == 'folder'
        )
        end
        result
      end

      def link_for(path)
        file = box_client.file(path)
        file.create_shared_link
        file.shared_link.download_url
      end

      def details(f)
      end

      def auth_link
        callback = connector_response_url(config[:url_options])
        oauth_client.authorize_url(callback.to_s)
      end

      def authorized?
        #false
        @token.present?
      end

      def connect(params,data)
        @token = oauth_client.get_access_token(params[:code]).token
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