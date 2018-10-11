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
        @downloaded_files = {}
        super(config_values)
      end

      def icon
        'dropbox'
      end

      def validate_config
        raise InitializationError, 'Dropbox driver requires a :client_id argument' unless config[:client_id]
        raise InitializationError, 'Dropbox driver requires a :client_secret argument' unless config[:client_secret]
      end

      def contents(path = '')
        path = '/' + path unless path == ''
        response = client.list_folder(path)
        @entries = response.entries.map { |entry| FileEntryFactory.build(metadata: entry, key: key) }
        @sorter.call(@entries)
      end

      def downloaded_file_for(path)
        return @downloaded_files[path] if @downloaded_files.key?(path)

        temp_file = Tempfile.open(File.basename(path), encoding: 'ascii-8bit')
        client.download(path) do |chunk|
          temp_file.write chunk
        end
        temp_file.close
        @downloaded_files[path] = temp_file
      end

      def uri_for(path)
        temp_file = downloaded_file_for(path)
        "file://#{temp_file.path}"
      end

      def file_size_for(path)
        downloaded_file = downloaded_file_for(path)
        size = File.size(downloaded_file.path)
        size.to_i
      rescue StandardError => error
        Rails.logger.error "Failed to find the file size for #{path}: #{error}"
        0
      end

      def link_for(path)
        uri = uri_for(path)
        file_name = File.basename(path)
        file_size = file_size_for(path)

        [uri, { file_name: file_name, file_size: file_size }]
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
