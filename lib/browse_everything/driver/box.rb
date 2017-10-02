module BrowseEverything
  module Driver
    # Driver for accessing the Box API (https://www.box.com/home)
    class Box < Base
      require 'boxr'
      require 'ruby-box'

      ITEM_LIMIT = 99999

      def icon
        'cloud'
      end

      def validate_config
        return if config[:client_id] && config[:client_secret]
        raise BrowseEverything::InitializationError, 'Box driver requires both :client_id and :client_secret argument'
      end

      # @param [String] id of the file or folder in Box
      # @return [Array<RubyBox::File>]
      def contents(id = '')
        if id.empty?
          folder = box_client.folder_from_id(Boxr::ROOT)
          results = []
        else
          folder = box_client.folder_from_id(id)
          results = [parent_directory(folder)]
        end

        box_client.folder_items(folder, limit: ITEM_LIMIT, offset: 0, fields: %w(name size created_at)).collect do |f|
          results << directory_entry(f)
        end

        results
      end

      # @param [String] id of the file in Box
      # @return [Array<String, Hash>]
      def link_for(id)
        refresh!
        file = box_client.file_from_id(id)
        download_url = [Boxr::Client::FILES_URI, id, 'content'].join('/')
        auth_header = { 'Authorization' => "Bearer #{@token}" }
        extras = { auth_header: auth_header, expires: expiration_time, file_name: file.name, file_size: file.size.to_i }
        [download_url, extras]
      end

      # @return [String]
      # Authorization url that is used to request the initial access code from Box
      def auth_link
        box_auth_url
      end

      # @return [Boolean]
      def authorized?
        box_token.present? && !token_expired?
      end

      # @return [Hash]
      # Gets the appropriate tokens from Box using the access code returned from :auth_link:
      def connect(params, _data)
        register_access_token(Boxr.get_tokens(params[:code], client_id: config[:client_id], client_secret: config[:client_secret]))
      end

      def refresh!
        Boxr.refresh_tokens(box_refresh_token,
                            client_id: config[:client_id],
                            client_secret: config[:client_secret])
      end

      private

        def token_expired?
          return true if expiration_time.nil?
          expiration_int = expiration_time.is_a?(String) ? Time.zone.parse(expiration_time).to_i : expiration_time.to_i
          Time.current.to_i > expiration_int
        end

        def box_client
          refresh! if token_expired?

          Boxr::Client.new(box_token,
                           refresh_token: box_refresh_token,
                           client_id: config[:client_id],
                           client_secret: config[:client_secret])
        end

        def box_session(token = nil, refresh_token = nil)
          RubyBox::Session.new(client_id: config[:client_id],
                               client_secret: config[:client_secret],
                               access_token: token,
                               refresh_token: refresh_token)
        end

        def box_auth_url
          Boxr.oauth_url('box', client_id: config[:client_id]).to_s
        end

        # If there is an active session, {@token} will be set by {BrowseEverythingController} using data stored in the
        # session. However, if there is no prior session, or the token has expired, we reset it here using # a new
        # access_token received from {#box_session}.
        #
        # @param [OAuth2::AccessToken] access_token
        def register_access_token(access_token)
          @token = {
            'token' => access_token.access_token,
            'refresh_token' => access_token.refresh_token,
            'expires_at' => (Time.current + access_token.expires_in)
          }
        end

        def box_token
          return unless @token
          @token.fetch('token', nil)
        end

        def box_refresh_token
          return unless @token
          @token.fetch('refresh_token', nil)
        end

        def expiration_time
          return unless @token
          @token.fetch('expires_at', nil)
        end

        # Used to represent the ".." parent directory of the folder
        def parent_directory(folder)
          BrowseEverything::FileEntry.new(Pathname(folder.name).join('..'), '', '..', 0, Time.current, true)
        end

        def directory_entry(f)
          BrowseEverything::FileEntry.new(f.id, "#{key}:#{f.id}", f.name, f.size, Time.zone.parse(f.created_at), f.type == 'folder')
        end
    end
  end
end
