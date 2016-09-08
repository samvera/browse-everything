module BrowseEverything
  module Driver
    class GoogleDrive < Base
      require 'google/apis/drive_v2'
      require 'signet'

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
        return to_enum(:contents, path)

        default_params = { }
        page_token = nil
        files = []
        begin
          unless path.blank?
            default_params[:q] = "'#{path}' in parents"
          end
          unless page_token.blank?
            default_params[:page_token] = page_token
          end
          response = drive.list_files(default_params)
          page_token = response.next_page_token
          response.items.select do |file|
            path.blank? ? (file["parents"].blank? or file["parents"].any?{|p| p["isRoot"] }) : true
          end.each do |file|
            d = details(file, path)
            yield d if d
          end
        end while !page_token.blank?
      end

      def details(file, path='')
        if file.web_content_link or file.mime_type == "application/vnd.google-apps.folder"
          BrowseEverything::FileEntry.new(
            file.id,
            "#{self.key}:#{file.id}",
            file.name,
            file.size.to_i,
            file.modified_time,
            file.mime_type == "application/vnd.google-apps.folder",
            file.mime_type == "application/vnd.google-apps.folder" ?
                                  "directory" :
                                  file.mime_type
          )
        end
      end

      def link_for(id)
        file = drive.get_file(id)
        auth_header = {'Authorization' => "Bearer #{client.authorization.access_token.to_s}"}
        extras = { 
          auth_header: auth_header,
          expires: 1.hour.from_now, 
          file_name: file.name,
          file_size: file.size.to_i
        }
        [file.web_content_link, extras]
      end

      def auth_link
        auth_client.authorization_uri
      end

      def authorized?
        token.present?
      end

      def connect(params, data)
        auth_client.code = params[:code]
        self.token = auth_client.fetch_access_token!
      end

      def drive
        @drive ||= Google::Apis::DriveV3::DriveService.new.tap do |s|
          s.authorization = authorization
        end
      end

      private

      def token_expired?
        return true if token.nil?
        token.expired?
      end

      def authorization
        if auth_client?
          auth_client
        elsif token.present?
          auth_client.update_token!(token)
          self.token = auth_client.fetch_access_token! if token_expired?
          auth_client
        end
      end

      def auth_client
        @auth_client ||= Signet::OAuth2::Client.new token_credential_uri: 'https://www.googleapis.com/oauth2/v3/token',
                                                    authorization_uri: 'https://accounts.google.com/o/oauth2/auth',
                                                    scope: 'https://www.googleapis.com/auth/drive',
                                                    client_id: config[:client_id],
                                                    client_secret: config[:client_secret]
      end

      def auth_client?
        !@auth_client.nil?
      end

    end

  end
end
