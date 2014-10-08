module BrowseEverything
  module Driver
    class GoogleDrive < Base

      require 'google/api_client'

      def icon
        'google-plus-sign'
      end

      def validate_config
        unless config[:client_id]
          raise BrowseEverything::InitializationError, "GoogleDrive driver requires a :client_id argument"
        end
        unless config[:client_secret]
          raise BrowseEverything::InitializationError, "GoogleDrive driver requires a :client_secret argument"
        end
      end

      def contents(path='')
        default_params = { }
        page_token = nil
        files = []
        begin
          unless path.blank?
            default_params[:q] = "'#{path}' in parents"
          end
          unless page_token.blank?
            default_params[:pageToken] = page_token
          end
          api_result = oauth_client.execute( api_method: drive.files.list, parameters: default_params )
          response = JSON.parse(api_result.response.body)
          page_token = response["nextPageToken"]
          response["items"].select do |file|
            path.blank? ? (file["parents"].blank? or file["parents"].any?{|p| p["isRoot"] }) : true
          end.each do |file|
            files << details(file, path)
          end
        end while !page_token.blank?
        files.compact
      end

      def details(file, path='')
        if file["downloadUrl"] or file["mimeType"] == "application/vnd.google-apps.folder"
          BrowseEverything::FileEntry.new(
            file["id"],
            "#{self.key}:#{file["id"]}",
            file["title"],
            (file["fileSize"] || 0),
            Time.parse(file["modifiedDate"]),
            file["mimeType"] == "application/vnd.google-apps.folder",
            file["mimeType"] == "application/vnd.google-apps.folder" ?
                                  "directory" :
                                  file["mimeType"]
          )
        end
      end

      def link_for(id)
        api_method = drive.files.get
        api_result = oauth_client.execute(api_method: api_method, parameters: {fileId: id})
        download_url = JSON.parse(api_result.response.body)["downloadUrl"]
        auth_header = {'Authorization' => "Bearer #{oauth_client.authorization.access_token.to_s}"}
        extras = { 
          auth_header: auth_header,
          expires: 1.hour.from_now, 
          file_name: api_result.data.title,
          file_size: api_result.data.fileSize.to_i
        }
        [download_url, extras]
      end

      def auth_link
        oauth_client.authorization.authorization_uri.to_s
      end

      def authorized?
        @token.present?
      end

      def connect(params, data)
        oauth_client.authorization.code = params[:code]
        @token = oauth_client.authorization.fetch_access_token!
      end

      def drive
        oauth_client.discovered_api('drive', 'v2')
      end

      private

      #As per issue http://stackoverflow.com/questions/12572723/rails-google-client-api-unable-to-exchange-a-refresh-token-for-access-token

      #patch start
      def token_expired?(token)
        client=@client
        result = client.execute( api_method: drive.files.list, parameters: {} )
        (result.status != 200)
      end

      def exchange_refresh_token( refresh_token )
        client=oauth_client
        client.authorization.grant_type = 'refresh_token'
        client.authorization.refresh_token = refresh_token
        client.authorization.fetch_access_token!
        client.authorization
        client
      end
      #patch end

      def oauth_client
        if @client.nil?
          callback = connector_response_url(config[:url_options])
          @client = Google::APIClient.new
          @client.authorization.client_id = config[:client_id]
          @client.authorization.client_secret = config[:client_secret]
          @client.authorization.scope = "https://www.googleapis.com/auth/drive"
          @client.authorization.redirect_uri = callback
          @client.authorization.update_token!(@token) if @token.present?
           #Patch start
          @client = exchange_refresh_token(@token["refresh_token"]) if @token.present? && token_expired?(@token)
          #Patch end
        end
        #todo error checking here
        @client
      end

    end

  end
end
