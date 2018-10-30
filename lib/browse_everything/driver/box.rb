# frozen_string_literal: true

require 'ruby-box'
require_relative 'authentication_factory'

module BrowseEverything
  module Driver
    # Driver for accessing the Box API (https://www.box.com/home)
    class Box < Base
      ITEM_LIMIT = 99999

      class << self
        attr_accessor :authentication_klass

        def default_authentication_klass
          RubyBox::Session
        end
      end

      # Constructor
      # @param config_values [Hash] configuration for the driver
      def initialize(config_values)
        self.class.authentication_klass ||= self.class.default_authentication_klass
        super(config_values)
      end

      def icon
        'cloud'
      end

      def validate_config
        return if config[:client_id] && config[:client_secret]
        raise InitializationError, 'Box driver requires both :client_id and :client_secret argument'
      end

      # @param [String] id of the file or folder in Box
      # @return [Array<RubyBox::File>]
      def contents(id = '')
        folder = id.empty? ? box_client.root_folder : box_client.folder_by_id(id)
        @entries = []

        folder.items(ITEM_LIMIT, 0, %w[name size created_at]).collect do |f|
          @entries << directory_entry(f)
        end
        @sorter.call(@entries)
      end

      # @param [String] id of the file in Box
      # @return [Array<String, Hash>]
      def link_for(id)
        file = box_client.file_by_id(id)
        download_url = file.download_url
        auth_header = { 'Authorization' => "Bearer #{@token}" }
        extras = { auth_header: auth_header, expires: 1.hour.from_now, file_name: file.name, file_size: file.size.to_i }
        [download_url, extras]
      end

      # @return [String]
      # Authorization url that is used to request the initial access code from Box
      def auth_link(*_args)
        box_session.authorize_url(callback.to_s)
      end

      # @return [Boolean]
      def authorized?
        box_token.present? && box_refresh_token.present? && !token_expired?
      end

      # @return [Hash]
      # Gets the appropriate tokens from Box using the access code returned from :auth_link:
      def connect(params, _data, _url_options)
        register_access_token(box_session.get_access_token(params[:code]))
      end

      private

        def token_expired?
          return true if expiration_time.nil?
          Time.now.to_i > expiration_time
        end

        def box_client
          if token_expired?
            session = box_session
            register_access_token(session.refresh_token(box_refresh_token))
          end
          RubyBox::Client.new(box_session)
        end

        def session
          AuthenticationFactory.new(
            self.class.authentication_klass,
            client_id: config[:client_id],
            client_secret: config[:client_secret],
            access_token: box_token,
            refresh_token: box_refresh_token
          )
        end

        def authenticate
          session.authenticate
        end

        def box_session
          authenticate
        end

        # If there is an active session, {@token} will be set by {BrowseEverythingController} using data stored in the
        # session. However, if there is no prior session, or the token has expired, we reset it here using # a new
        # access_token received from {#box_session}.
        #
        # @param [OAuth2::AccessToken] access_token
        def register_access_token(access_token)
          @token = {
            'token' => access_token.token,
            'refresh_token' => access_token.refresh_token,
            'expires_at' => access_token.expires_at
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
          @token.fetch('expires_at', nil).to_i
        end

        def directory_entry(file)
          BrowseEverything::FileEntry.new(file.id, "#{key}:#{file.id}", file.name, file.size, file.created_at, file.type == 'folder')
        end
    end
  end
end
