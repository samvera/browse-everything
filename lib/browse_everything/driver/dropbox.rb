# frozen_string_literal: true

require 'dropbox_api'
require_relative 'authentication_factory'

module BrowseEverything
  module Driver
    class Dropbox < Base
      class FileEntryFactory
        def self.build(metadata:, key:)
          factory_klass = klass_for metadata
          factory_klass.build(metadata: metadata, key: key)
        end

        class << self
          private

          def klass_for(metadata)
            case metadata
            when DropboxApi::Metadata::File
              FileFactory
            else
              ResourceFactory
            end
          end
        end
      end

      class ResourceFactory
        def self.build(metadata:, key:)
          path = metadata.path_display
          BrowseEverything::FileEntry.new(
            path,
            [key, path].join(':'),
            File.basename(path),
            nil,
            nil,
            true
          )
        end
      end

      class FileFactory
        def self.build(metadata:, key:)
          path = metadata.path_display
          BrowseEverything::FileEntry.new(
            path,
            [key, path].join(':'),
            File.basename(path),
            metadata.size,
            metadata.client_modified,
            false
          )
        end
      end

      class << self
        attr_accessor :authentication_klass

        def default_authentication_klass
          DropboxApi::Authenticator
        end
      end

      # Constructor
      # @param config_values [Hash] configuration for the driver
      def initialize(config_values)
        self.class.authentication_klass ||= self.class.default_authentication_klass
        super(config_values)
      end

      def icon
        'dropbox'
      end

      def handle_deprecated_config(deprecated_key, new_key)
        warn("[DEPRECATION] Dropbox driver: `#{deprecated_key}` is deprecated.  Please use `#{new_key}` instead.")
        @config[new_key] = @config[deprecated_key]
      end

      def validate_config
        handle_deprecated_config(:app_key, :client_id) if config[:app_key]
        handle_deprecated_config(:app_secret, :client_secret) if config[:app_secret]
        raise InitializationError, 'Dropbox driver requires a :client_id argument' unless config[:client_id]
        raise InitializationError, 'Dropbox driver requires a :client_secret argument' unless config[:client_secret]
      end

      def contents(path = '', _page_index = 0)
        response = client.list_folder(path)
        @entries = response.entries.map { |entry| FileEntryFactory.build(metadata: entry, key: key) }
        @sorter.call(@entries)
      end

      def download(path)
        temp_file = Tempfile.open(File.basename(path), encoding: 'ascii-8bit')
        client.download(path) do |chunk|
          temp_file.write chunk
        end
        temp_file.close
        temp_file
      end

      def uri_for(path)
        temp_file = download(path)
        uri = ::Addressable::URI.new(scheme: 'file', path: temp_file.path)
        uri.to_s
      end

      def link_for(path)
        [uri_for(path), {}]
      end

      def auth_link(url_options)
        authenticator.authorize_url redirect_uri: redirect_uri(url_options)
      end

      def connect(params, _data, url_options)
        auth_bearer = authenticator.get_token params[:code], redirect_uri: redirect_uri(url_options)
        self.token = auth_bearer.token
      end

      def authorized?
        token.present?
      end

      private

        def session
          AuthenticationFactory.new(
            self.class.authentication_klass,
            config[:client_id],
            config[:client_secret]
          )
        end

        def authenticate
          session.authenticate
        end

        def authenticator
          @authenticator ||= authenticate
        end

        def client
          DropboxApi::Client.new(token)
        end

        def redirect_uri(url_options)
          connector_response_url(**url_options)
        end
    end
  end
end
