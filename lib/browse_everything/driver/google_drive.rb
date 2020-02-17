# frozen_string_literal: true
require 'google/apis/drive_v3'
require 'googleauth'
require 'googleauth/stores/file_token_store'

module BrowseEverything
  class Driver
    # The Drivers class for interfacing with Google Drive as a storage provider
    class GoogleDrive < BrowseEverything::Driver
      # Determine whether or not a Google Drive resource is a Folder
      # @return [Boolean]
      def self.folder?(gdrive_file)
        gdrive_file.mime_type == 'application/vnd.google-apps.folder'
      end

      def find_bytestream(id:)
        gdrive_file = drive_service.get_file(id, fields: 'id, name, modifiedTime, size, mimeType')
        build_bytestream(gdrive_file)
      end

      def find_container(id:)
        gdrive_container = drive_service.get_file(id, fields: 'id, name, modifiedTime')
        build_container(gdrive_container)
      end

      def root_container
        batch_request_path
        build_root_container
      end

      # Provides a URL for authorizing against Google Drive
      # @return [String] the URL
      def authorization_url
        Addressable::URI.parse(authorizer.get_authorization_url)
      end

      # Generate the URL for the API callback
      # Note: this is tied to the routes used for the OAuth callbacks
      # @return [String]
      def callback
        provider_authorize_url(callback_options)
      end

      private

        def build_root_container
          bytestreams = @resources.select { |child| child.is_a?(Bytestream) }
          containers = @resources.select { |child| child.is_a?(Container) }
          Container.new(
            id: '/',
            bytestreams: bytestreams,
            containers: containers,
            location: '',
            name: 'root',
            mtime: DateTime.current
          )
        end

        def build_container(gdrive_container)
          location = "key:#{gdrive_container.id}"
          modified_time = gdrive_container.modified_time || Time.new.utc
          batch_request_path(gdrive_container.id)
          bytestreams = @resources.select { |child| child.is_a?(Bytestream) }
          containers = @resources.select { |child| child.is_a?(Container) }

          Container.new(
            id: gdrive_container.id,
            bytestreams: bytestreams,
            containers: containers,
            location: location,
            name: gdrive_container.name,
            mtime: modified_time
          )
        end

        def build_bytestream(gdrive_file)
          location = "key:#{gdrive_file.id}"
          modified_time = gdrive_file.modified_time || Time.new.utc

          BrowseEverything::Bytestream.new(
            id: gdrive_file.id,
            location: location,
            name: gdrive_file.name,
            size: gdrive_file.size.to_i,
            mtime: modified_time,
            media_type: gdrive_file.mime_type,
            uri: build_download_url(gdrive_file.id)
          )
        end

        def build_download_url(id)
          "https://www.googleapis.com/drive/v3/files/#{id}?alt=media"
        end

        def build_resource(gdrive_file, bytestream_tree, container_tree)
          location = "key:#{gdrive_file.id}"
          modified_time = gdrive_file.modified_time || Time.new.utc

          if self.class.folder?(gdrive_file)
            bytestream_ids = []
            container_ids = []

            bytestream_ids = bytestream_tree[gdrive_file.id] if bytestream_tree.key?(gdrive_file.id)
            container_ids = container_tree[gdrive_file.id] if container_tree.key?(gdrive_file.id)
            # @todo this should invoke #build_container
            BrowseEverything::Container.new(
              id: gdrive_file.id,
              bytestream_ids: bytestream_ids,
              container_ids: container_ids,
              location: location,
              name: gdrive_file.name,
              mtime: modified_time
            )
          else
            # @todo this should invoke #build_bytestream
            BrowseEverything::Bytestream.new(
              id: gdrive_file.id,
              location: location,
              name: gdrive_file.name,
              size: gdrive_file.size.to_i,
              mtime: modified_time,
              media_type: gdrive_file.mime_type,
              uri: build_download_url(gdrive_file.id)
            )
          end
        end

        # This should be renamed, given that the path is passed in the
        # request_params Hash
        def request_path(drive:, request_params:)
          resources = []
          @resources = []
          container_tree = {}
          bytestream_tree = {}

          drive.list_files(request_params.to_h) do |file_list, error|
            # Raise an exception if there was an error Google API's
            raise error if error.present?

            members = file_list.files
            members.map do |gdrive_file|
              # All GDrive Folders have File entries
              if self.class.folder?(gdrive_file)
                container_tree[gdrive_file.id] = []
                bytestream_tree[gdrive_file.id] = []
              end
              resources << gdrive_file.id

              # A GDrive file may have multiple parents
              gdrive_file.parents do |parent|
                if resources.include?(parent)
                  if self.class.folder?(gdrive_file)
                    container_tree[parent] << gdrive_file.id
                  else
                    bytestream_tree[parent] << gdrive_file.id
                  end
                end
              end
            end

            # This ensures that the entire tree is build for the objects
            resources = members.map do |gdrive_file|
              # Here the API responses are parsed into BrowseEverything objects
              build_resource(gdrive_file, bytestream_tree, container_tree)
            end

            # This is needed (rather than returning the results) given the
            # manner by which Google Drive API transactions are undertaken
            @resources += resources
            request_params.page_token = file_list.next_page_token
          end

          # Recurse if there are more pages of results
          request_path(drive: drive, request_params: request_params) if request_params.page_token.present?
        end

        def batch_request_path(path = '')
          drive_service.batch do |drive|
            request_params = Auth::Google::RequestParameters.new
            request_params.q += " and '#{path}' in parents " if path.present?
            request_path(drive: drive, request_params: request_params)
          end
          @resources
        end

        def config
          values = BrowseEverything.config['google_drive'] || {
            client_id: nil,
            client_secret: nil
          }

          OpenStruct.new(values)
        end

        def client_secrets
          {
            Google::Auth::ClientId::WEB_APP => {
              Google::Auth::ClientId::CLIENT_ID => config.client_id,
              Google::Auth::ClientId::CLIENT_SECRET => config.client_secret
            }
          }
        end

        # Client ID for authorizing against the Google API's
        # @return [Google::Auth::ClientId]
        def client_id
          @client_id ||= Google::Auth::ClientId.from_hash(client_secrets)
        end

        def scope
          Google::Apis::DriveV3::AUTH_DRIVE_READONLY
        end

        # This is required for using the googleauth Gem
        # @see http://www.rubydoc.info/gems/googleauth/Google/Auth/Stores/FileTokenStore FileTokenStore for googleauth
        # @return [Tempfile] temporary file within which to cache credentials
        def file_token_store_path
          Rails.root.join('gdrive.yml')
        end

        # Token store file used for authorizing against the Google API's
        # (This is fundamentally used to temporarily cache access tokens)
        # @return [Google::Auth::Stores::FileTokenStore]
        def token_store
          Google::Auth::Stores::FileTokenStore.new(file: file_token_store_path)
        end

        def build_user_authorizer
          Google::Auth::UserAuthorizer.new(
            client_id,
            scope,
            token_store,
            callback
          )
        end

        # Authorization Object for Google API
        # @return [Google::Auth::UserAuthorizer]
        def authorizer
          @authorizer ||= build_user_authorizer
        end

        # Provides the user ID for caching access tokens
        # (This is a hack which attempts to anonymize the access tokens)
        # @return [String] the ID for the user
        def user_id
          'browse_everything'
        end

        # The authorization code is retrieved from the session
        # @raise [Signet::AuthorizationError] this error is raised if the authorization is invalid
        def credentials
          @credentials = authorizer.get_credentials(user_id)
          # Renew the access token if the credentials are non-existent or expired
          if @credentials.nil? || @credentials.expired?
            @credentials = authorizer.get_and_store_credentials_from_code(user_id: user_id, code: @auth_code)
            return @credentials
          end

          # This should work with simply redeeming the code with @credentials
          # Why this is needed should be further explored
          overridden_credentials = Auth::Google::Credentials.new
          overridden_credentials.client_id = client_id.id
          overridden_credentials.client_secret = client_id.secret
          overridden_credentials.update_token!('access_token' => @credentials.access_token)
          @credentials = overridden_credentials
        end
        delegate :access_token, to: :credentials
        alias auth_token access_token

        # Construct a new object for interfacing with the Google Drive API
        # @return [Google::Apis::DriveV3::DriveService]
        def drive_service
          raise StandardError if auth_code.nil?

          Google::Apis::DriveV3::DriveService.new.tap do |drive_service|
            drive_service.authorization = credentials
          end
        end
    end
  end
end
