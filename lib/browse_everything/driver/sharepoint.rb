# frozen_string_literal: true

require_relative 'authentication_factory'

module BrowseEverything
  module Driver
    # Driver for accessing the MS-Graph API (https://learn.microsoft.com/en-us/graph/overview)
    class Sharepoint < Base
      class << self
        attr_accessor :authentication_klass

        def default_authentication_klass
          BrowseEverything::Auth::Sharepoint::Session
        end
      end

      # Constructor
      # @param [Hash] config_values The configuration for the driver
      def initialize(config_values)
        self.class.authentication_klass ||= self.class.default_authentication_klass
        super(config_values)
      end

      def icon
        'cloud'
      end

      # Validates the configuration for the Sharepoint provider
      def validate_config
        raise InitializationError, 'Sharepoint driver requires a :client_id argument' unless config[:client_id]
        raise InitializationError, 'Sharepoint driver requires a :client_secret argument' unless config[:client_secret]
        raise InitializationError, 'Sharepoint driver requires a :tenant_id argument' unless config[:tenant_id]
        raise InitializationError, 'Sharepoint driver requires a :redirect_uri argument' unless config[:redirect_uri]
        raise InitializationError, 'Sharepoint driver requires a :scope argument' unless config[:scope]
      end

      # Retrieves the file entry objects for a given path to MS-graph drive resource
      # @param [String] id The id of the file or folder
      # @return [Array<BrowseEverything::FileEntry>]
      def contents(id = '')
        token_refresh if authorized?

        folder = []
        if id.empty?
          # The metadata returned does not have anything identifiable as results being teams.
          # To facilitate getting subsequent routes correct we add a teams identifier.
          folder << teams.map { |t| t.merge!({ teams: true }) }
          folder << drives
        else
          folder << items_by_id(id)
        end

        values = []

        folder.flatten.each do |f|
          # Entries in folder array should not have a value key.
          # Skip entries that do to prevent blank folders in list.
          next if f['value']
          values << directory_entry(f)
        end
        @entries = values.compact

        @sorter.call(@entries)
      end

      # @return [String]
      # Authorization url that is used to request the initial access code from Sharepoint/Onedrive/365/etc
      def auth_link(*_args)
        Addressable::URI.parse("https://login.microsoftonline.com/#{config[:tenant_id]}/oauth2/v2.0/authorize?#{auth_query_string}")
      end

      # @return [Boolean]
      def authorized?
        @token.present?
      end

      def authorize!
        return if @code.blank?
        register_access_token(sharepoint_session.get_access_token(@code))
        @code = nil
        @token
      end

      def connect(params, _data, _url_options)
        @code = params[:code]
        authorize!
      end

      # @param [String] id The id of the file on MS graph drive
      # @return [Array<String, Hash>]
      def link_for(id)
        file = items_by_id(id)
        extras = { file_name: file['name'], file_size: file['size'].to_i }
        [download_url(file), extras]
      end

      private

      def auth_query_string
        query = []
        base = config.slice('client_id', 'scope', 'redirect_uri')
        base.each do |k, v|
          query += ["#{k}=#{v}"]
        end
        query += ["response_type=code", @consent_refresh.present? ? "prompt=consent" : nil].compact

        query.join('&')
      end

      def session
        AuthenticationFactory.new(
          self.class.authentication_klass,
          client_id: config[:client_id],
          client_secret: config[:client_secret],
          tenant_id: config[:tenant_id],
          scope: config[:scope],
          redirect_uri: config[:redirect_uri],
          code: @code.presence,
          access_token: @token.presence
        )
      end

      def authenticate
        session.authenticate
      end

      def sharepoint_session
        @sharepoint_session ||= authenticate
      end

      def token_refresh
        return @token unless token_expired?

        register_access_token(sharepoint_session.refresh_token)
      end

      # If there is an active session, {@token} will be set by {BrowseEverythingController} using data stored in the
      # session.
      #
      # @param [OAuth2::AccessToken] access_token
      def register_access_token(access_token)
        @token = {
          'token' => access_token.token,
          'expires_in' => access_token.expires_in,
          'expires_at' => access_token.expires_at,
          'refresh_token' => access_token.refresh_token
        }
      end

      def sharepoint_token
        return unless @token
        @token.fetch('token', nil)
      end

      def expiration_time
        return unless @token
        expires_at = @token.fetch('expires_at', nil)
        # rubocop: disable Style/SafeNavigation
        expires_at.nil? ? nil : expires_at.to_i
        # rubocop: enable Style/SafeNavigation
      end

      def token_expired?
        return true if expiration_time.nil?
        Time.now.to_i > expiration_time
      end

      def sharepoint_request(sharepoint_uri)
        @auth = "Bearer " + sharepoint_token

        uri = URI.parse(sharepoint_uri)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true if uri.scheme == 'https'

        response = http.start do
          request = Net::HTTP::Get.new(uri.request_uri, { 'Authorization' => @auth })
          http.request(request)
        end

        parsed_response = JSON.parse(response.body)
        # If permissions are changed, we need to redirect the user to the consent
        # page so they can agree to the new permissions. Set flag for that here.
        @consent_refresh = parsed_response.dig('error', 'message')&.include?('Missing scope permissions on the request.') ? true : false

        parsed_response
      end

      # Constructs a BrowseEverything::FileEntry object for a Sharepoint file
      # resource
      # @param [String] file The ID of the file resource
      # @return [BrowseEverything::File]
      def directory_entry(file)
        BrowseEverything::FileEntry.new(make_path(file),
                                        [key, make_path(file)].join(':'),
                                        file['displayName'] ? file['displayName'] : file['name'],
                                        file['size'] ? file['size'] : nil,
                                        file['lastModifiedDateTime'] ? Date.parse(file['lastModifiedDateTime']) : nil,
                                        folder?(file))
      end

      # Derives a path from item (file or folder or drive) metadata
      # that can be used in subsequent items_by_id calls
      def make_path(file)
        if file['parentReference'].present?
          folder?(file) ? "#{file['parentReference']['driveId']}/items/#{file['id']}/children" : "#{file['parentReference']['driveId']}/items/#{file['id']}"
        elsif file[:teams].present?
          "#{file['id']}/drives"
        else
          "#{file['id']}/root/children"
        end
      end

      def folder?(file)
        file['file'].blank?
      end

      def teams
        @teams ||= sharepoint_request("https://graph.microsoft.com/v1.0/me/joinedTeams?$select=id,displayName")['value']
      end

      def drives
        @drives ||= sharepoint_request("https://graph.microsoft.com/v1.0/me/drives?$select=id,name,lastModifiedDateTime")['value']
      end

      def items_by_id(id)
        item = if id.end_with?('drives')
                 sharepoint_request("https://graph.microsoft.com/v1.0/groups/#{id}")
               else
                 sharepoint_request("https://graph.microsoft.com/v1.0/me/drives/#{id}")
               end
        item['value'].presence || item
      end

      def download_url(file)
        file['@microsoft.graph.downloadUrl']
      end
    end
  end
end
