require 'google/apis/drive_v3'
require 'googleauth'
require 'googleauth/stores/file_token_store'
require_relative 'google_drive/credentials'
require_relative 'google_drive/request_parameters'

module BrowseEverything
  module Driver
    class GoogleDrive < Base
      attr_reader :credentials

      # The token here must be set using a Hash
      # @param value [String, Hash] the new access token
      def token=(value)
        # This is invoked within BrowseEverythingController using a Hash
        value = value.fetch('access_token') if value.is_a? Hash

        # Restore the credentials if the access token string itself has been cached
        restore_credentials(value) if @credentials.nil?

        super(value)
      end

      def icon
        'google-plus-sign'
      end

      # Validates the configuration for the Google Drive provider
      def validate_config
        raise BrowseEverything::InitializationError, 'GoogleDrive driver requires a :client_id argument' unless config[:client_id]
        raise BrowseEverything::InitializationError, 'GoogleDrive driver requires a :client_secret argument' unless config[:client_secret]
      end

      # Retrieve the file details
      # @param file [Google::Apis::DriveV3::File] the Google Drive File
      # @param path [String] path for the resource details (unused)
      # @return [BrowseEverything::FileEntry] file entry for the resource node
      def details(file, _path = '')
        mime_folder = file.mime_type == 'application/vnd.google-apps.folder'
        BrowseEverything::FileEntry.new(
          file.id,
          "#{key}:#{file.id}",
          file.name,
          file.size.to_i,
          file.modified_time || DateTime.new,
          mime_folder,
          mime_folder ? 'directory' : file.mime_type
        )
      end

      # Lists the files given a Google Drive context
      # @param drive [Google::Apis::DriveV3::DriveService] the Google Drive context
      # @param request_params [RequestParameters] the object containing the parameters for the Google Drive API request
      # @param path [String] the path (default to the root)
      # @return [Array<BrowseEverything::FileEntry>] file entries for the path
      def list_files(drive, request_params, path: '')
        drive.list_files(request_params.to_h) do |file_list, error|
          # Raise an exception if there was an error Google API's
          if error.present?
            # In order to properly trigger reauthentication, the token must be cleared
            # Additionally, the error is not automatically raised from the Google Client
            @token = nil
            raise error
          end

          @files += file_list.files.map do |gdrive_file|
            details(gdrive_file, path)
          end

          request_params.page_token = file_list.next_page_token
        end

        @files += list_files(drive, request_params, path: path) if request_params.page_token.present?
      end

      # Retrieve the files for any given resource on Google Drive
      # @param path [String] the root or Folder path for which to list contents
      # @return [Array<BrowseEverything::FileEntry>] file entries for the path
      def contents(path = '')
        @files = []
        drive_service.batch do |drive|
          request_params = RequestParameters.new
          request_params.q = "'#{path}' in parents" unless path.blank?
          list_files(drive, request_params, path: path)
        end
        @files
      end

      # Retrieve a link for a resource
      # @param id [String] identifier for the resource
      # @return [Array<String, Hash>] authorized link to the resource
      def link_for(id)
        file = drive_service.get_file(id, fields: 'id, name, size')
        auth_header = { 'Authorization' => "Bearer #{credentials.access_token}" }
        extras = {
          auth_header: auth_header,
          expires: 1.hour.from_now,
          file_name: file.name,
          file_size: file.size.to_i
        }
        [download_url(id), extras]
      end

      # Provides a URL for authorizing against Google Drive
      # @return [String] the URL
      def auth_link
        Addressable::URI.parse(authorizer.get_authorization_url)
      end

      # Whether or not the current provider is authorized
      # @return [true,false]
      def authorized?
        @token.present?
      end

      # Client ID for authorizing against the Google API's
      # @return [Google::Auth::ClientId]
      def client_id
        @client_id ||= Google::Auth::ClientId.from_hash(client_secrets)
      end

      # Token store file used for authorizing against the Google API's
      # (This is fundamentally used to temporarily cache access tokens)
      # @return [Google::Auth::Stores::FileTokenStore]
      def token_store
        Google::Auth::Stores::FileTokenStore.new(file: file_token_store_path)
      end

      # Authorization Object for Google API
      # @return [Google::Auth::UserAuthorizer]
      def authorizer
        @authorizer ||= Google::Auth::UserAuthorizer.new(client_id, scope, token_store, callback)
      end

      # Request to authorize the provider
      # This is *the* method which, passing an HTTP request, redeems an authorization code for an access token
      # @return [String] a new access token
      def authorize!
        @credentials = authorizer.get_credentials_from_code(user_id: user_id, code: code)
        @token = @credentials.access_token
        @code = nil # The authorization code can only be redeemed for an access token once
        @token
      end

      # This is the method accessed by the BrowseEverythingController for authorizing using an authorization code
      # @param params [Hash] HTTP response passed to the OAuth callback
      # @param _data [Object,nil] an unused parameter
      # @return [String] a new access token
      def connect(params, _data)
        @code = params[:code]
        authorize!
      end

      # Construct a new object for interfacing with the Google Drive API
      # @return [Google::Apis::DriveV3::DriveService]
      def drive_service
        Google::Apis::DriveV3::DriveService.new.tap do |s|
          s.authorization = credentials
        end
      end

      private

        def client_secrets
          {
            Google::Auth::ClientId::WEB_APP => {
              Google::Auth::ClientId::CLIENT_ID => config[:client_id],
              Google::Auth::ClientId::CLIENT_SECRET => config[:client_secret]
            }
          }
        end

        # This is required for using the googleauth Gem
        # @see http://www.rubydoc.info/gems/googleauth/Google/Auth/Stores/FileTokenStore FileTokenStore for googleauth
        # @return [Tempfile] temporary file within which to cache credentials
        def file_token_store_path
          Tempfile.new('gdrive.yaml')
        end

        def scope
          Google::Apis::DriveV3::AUTH_DRIVE
        end

        # Provides the user ID for caching access tokens
        # (This is a hack which attempts to anonymize the access tokens)
        # @return [String] the ID for the user
        def user_id
          'current_user'
        end

        # Please see https://developers.google.com/drive/v3/web/manage-downloads
        # @param id [String] the ID for the Google Drive File
        # @return [String] the URL for the file download
        def download_url(id)
          "https://www.googleapis.com/drive/v3/files/#{id}?alt=media"
        end

        # Restore the credentials for the Google API
        # @param access_token [String] the access token redeemed using an authorization code
        # @return Credentials credentials restored from a cached access token
        def restore_credentials(access_token)
          client = Credentials.new
          client.client_id = client_id.id
          client.client_secret = client_id.secret
          client.update_token!('access_token' => access_token)
          @credentials = client
        end
    end
  end
end
