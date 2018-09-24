# frozen_string_literal: true

require 'google/apis/drive_v3'
require 'googleauth'
require 'googleauth/stores/file_token_store'
require_relative 'authentication_factory'

module BrowseEverything
  module Driver
    class GoogleDrive < Base
      class << self
        attr_accessor :authentication_klass

        def default_authentication_klass
          Google::Auth::UserAuthorizer
        end
      end

      # Page methods
      # @note This should be refactored into a separate Class or mixin

      def pagination_klass
        Paginator::GoogleDrive
      end

      # Initialize the Hash used to map paths to pages
      # @return [Hash]
      def path_pages
        @path_pages ||= {}
      end

      # Generate a new Paginator object for a Drive resource path
      # @param [String] path
      # @return [Paginator]
      def new_pages_for_path!(path)
        new_pages = pagination_klass.new
        @path_pages[path] = new_pages
        new_pages
      end

      # Retrieve the Pagination object stored for a path
      # @param [String] path
      # @return [Paginator]
      def pages_for_path(path)
        path_pages[path] || new_pages_for_path!(path)
      end

      # Retrieve the Pagination object stored for the root path
      # @return [Paginator]
      def pages_for_root_path
        pages_for_path('')
      end

      # Return the number of pages for the content entry list retrieved by the provider
      # Defaults to 0
      # @param [String] browse_path the relative path to the resource directory tree
      # @return [Integer]
      def contents_pages
        pages_for_root_path.length
      end

      # Return the current page in the content entry list
      # Defaults to 0
      # @param [BrowseEverythingController] ctx the Controller context for the
      #   the request
      # @return [Integer]
      def contents_current_page(ctx)
        ctx.params[:page_token] || pagination_klass::FIRST_PAGE_TOKEN
      end

      def contents_next_page(_ctx)
        pages_for_root_path.page_tokens.last
      end

      def contents_last_page?(_ctx)
        pages_for_root_path.last_page?
      end

      attr_reader :credentials

      # Constructor
      # @param config_values [Hash] configuration for the driver
      def initialize(config_values)
        self.class.authentication_klass ||= self.class.default_authentication_klass
        super(config_values)
      end

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
        raise InitializationError, 'GoogleDrive driver requires a :client_id argument' unless config[:client_id]
        raise InitializationError, 'GoogleDrive driver requires a :client_secret argument' unless config[:client_secret]
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
          file.modified_time || Time.new,
          mime_folder,
          mime_folder ? 'directory' : file.mime_type
        )
      end

      # Lists the files given a Google Drive context
      # @param drive [Google::Apis::DriveV3::DriveService] the Google Drive context
      # @param request_params [RequestParameters] the object containing the parameters for the Google Drive API request
      # @param path [String] the path (default to the root)
      # @return [Array<BrowseEverything::FileEntry>] file entries for the path
      def list_files(drive, request_params, path: '', page_token:)
        pages = pages_for_path(path)

        # See https://developers.google.com/drive/api/v3/folder
        request_params.q += " and parents = 'root'" if path.empty?
        # Ensures that the next page token is used only if the pages have been populated by an initial response
        request_params.page_token = page_token unless page_token.nil? || page_token == pagination_klass::FIRST_PAGE_TOKEN

        drive.list_files(request_params.to_h) do |file_list, error|
          # Raise an exception if there was an error Google API's
          if error.present?
            @token = nil
            raise error
          end

          gdrive_file_details = file_list.files.map { |gdrive_file| details(gdrive_file, path) }

          page_index = page_token || pagination_klass::FIRST_PAGE_TOKEN
          pages[page_index] = gdrive_file_details

          pages.next_page_token = file_list.next_page_token || pagination_klass::LAST_PAGE_TOKEN
        end
      end

      # Retrieve the files for any given resource on Google Drive
      # @param path [String] the root or Folder path for which to list contents
      # @return [Array<BrowseEverything::FileEntry>] file entries for the path
      def contents(path = '', page_token = nil)
        # Return the cached response if its been indexed into memory
        pages = pages_for_path(path)
        return pages[page_token] if pages.indexed? page_token

        request_params = Auth::Google::RequestParameters.new
        request_params.q += " and '#{path}' in parents " if path.present?

        list_files(drive_service, request_params, path: path, page_token: page_token)

        page_index = page_token || pagination_klass::FIRST_PAGE_TOKEN
        pages[page_index]
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
      def auth_link(*_args)
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

      # Constructs the object capturing the state for the session
      # @see .default_authentication_klass
      # @return [Google::Auth::UserAuthorizer]
      def session
        AuthenticationFactory.new(
          self.class.authentication_klass,
          client_id,
          scope,
          token_store,
          callback
        )
      end

      delegate :authenticate, to: :session

      # Authorization Object for Google API
      # @return [Google::Auth::UserAuthorizer]
      def authorizer
        @authorizer ||= authenticate
      end

      # Request to authorize the provider
      # This is *the* method which, passing an HTTP request, redeems an
      #   authorization code for an access token
      # @return [String] a new access token
      def authorize!
        @credentials = authorizer.get_credentials_from_code(user_id: user_id, code: code)
        @token = @credentials.access_token
        @code = nil # The authorization code can only be redeemed for an access token once
        @token
      end

      # This is the method accessed by the BrowseEverythingController for
      #   authorizing using an authorization code
      # @param params [Hash] HTTP response passed to the OAuth callback
      # @param _data [Object,nil] an unused parameter
      # @return [String] a new access token
      def connect(params, _data = nil, _options = nil)
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

        # Generate the Hash used for initializing the API client
        # (Parses the configuration provided by the App.)
        # @return [Hash]
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

        # Provide the scope for the service granted access to the Google Drive
        # @return [String]
        def scope
          Google::Apis::DriveV3::AUTH_DRIVE_READONLY
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
          client = Auth::Google::Credentials.new
          client.client_id = client_id.id
          client.client_secret = client_id.secret
          client.update_token!('access_token' => access_token)
          @credentials = client
        end
    end
  end
end
