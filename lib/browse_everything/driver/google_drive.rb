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
        client = oauth_client
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
          api_result = client.execute( api_method: drive.files.list, parameters: default_params )
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
        client = oauth_client
        api_method = drive.files.get
        api_result = client.execute(api_method: api_method, parameters: {fileId: id})
        download_url = JSON.parse(api_result.response.body)["downloadUrl"]
        auth_header = "EXTRA_HEADERS=Authorization: Bearer #{client.authorization.access_token.to_s}"
        [download_url,auth_header].join('&')
      end

      def auth_link
        oauth_client.authorization.authorization_uri.to_s
      end

      def authorized?
        @token.present?
      end

      def connect(params, data)
        client = oauth_client
        client.authorization.code = params[:code]
        @token = client.authorization.fetch_access_token!
      end

      def drive
        oauth_client.discovered_api('drive', 'v2')
      end

      private

      def oauth_client
        callback = connector_response_url(config[:url_options])
        client = Google::APIClient.new
        client.authorization.client_id = config[:client_id]
        client.authorization.client_secret = config[:client_secret]
        client.authorization.scope = "https://www.googleapis.com/auth/drive"
        client.authorization.redirect_uri = callback
        client.authorization.update_token!(@token) if @token.present?
        #todo error checking here
        client
      end

    end

  end
end