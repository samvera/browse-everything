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
      # @param config_values [Hash] configuration for the driver
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
        raise InitializationError, 'Sharepoint driver requires a :domain argument' unless config[:domain]
        raise InitializationError, 'Sharepoint driver requires a :site_name argument' unless config[:site_name]
      end

      # Retrieves the file entry objects for a given path to MS-graph drive resource
      # @param [String] id of the file or folder
      # @return [Array<BrowseEverything::FileEntry>]
      def contents(id = '')
        sharepoint_session
        folder = id.empty? ? drives : items_by_id(id)
        values = []

        folder.each do |f|
          values << directory_entry(f)
        end
        @entries = values.compact

        @sorter.call(@entries)
      end

      # Not used as we currently only deal with Client Credentials flow
      # @return [String]
      # Authorization url that is used to request the initial access code from Sharepoint/Onedrive/365/etc
      def auth_link(*_args)
        Addressable::URI.parse("https://login.microsoftonline.com/kingsfund.org.uk/oauth2/v2.0/authorize")
      end

      # @return [Boolean]
      def authorized?
        unless @token.present?
          authorize!
        end
        @token.present?
      end

      def authorize!
        # TODO handle other authentication strategies (other than client_credentials)
        register_access_token(sharepoint_session.get_access_token)
      end

      # @param [String] id of the file on MS graph drive
      # @return [Array<String, Hash>]
      def link_for(id)
         file = items_by_id(id)
         extras = {file_name: file['name'], file_size: file['size'].to_i}
         [download_url(file), extras]
      end


      private

      def token_expired?
        return true if expiration_time.nil?
        Time.now.to_i > expiration_time
      end


      def session
        AuthenticationFactory.new(
          self.class.authentication_klass,
          client_id: config[:client_id],
          client_secret: config[:client_secret],
          access_token: sharepoint_token,
          domain: config[:domain],
          site_name: config[:site_name],
        )
      end

      def authenticate
        session.authenticate
      end

      # If there is an active session, {@token} will be set by {BrowseEverythingController} using data stored in the
      # session. 
      #
      # @param [OAuth2::AccessToken] access_token
      def register_access_token(access_token)
        @token = {
          'token' => access_token.token,
          'expires_at' => access_token.expires_at
        }
      end

      def sharepoint_token
        return unless @token
        @token.fetch('token', nil)
      end

      def expiration_time
        return unless @token
        @token.fetch('expires_at', nil).to_i
      end

      # Constructs a BrowseEverything::FileEntry object for a Sharepoint file
      # resource
      # @param file [String] ID to the file resource
      # @return [BrowseEverything::File]
      def directory_entry(file)
        BrowseEverything::FileEntry.new(make_path(file), [key, make_path(file)].join(':'), file['name'], file['size'] ? file['size'] : nil, Date.parse(file['lastModifiedDateTime']), folder?(file))
      end

      # Derives a path from item (file or folder or drive) metadata 
      # that can be used in subsequent items_by_id calls
      def make_path(file)
        if file['parentReference'].present? 
          folder?(file) ? "#{file['parentReference']['driveId']}/items/#{file['id']}/children" : "#{file['parentReference']['driveId']}/items/#{file['id']}"
        else 
          "#{file['id']}/root/children"
        end
      end

      def folder?(file)
        !file['file'].present?
      end

     ##################################################################
     # The below are all candidates to go its own sharepoint api module
     # or some such
     ##################################################################

      def sharepoint_request(sharepoint_uri)
        sharepoint_client
        @auth = "Bearer "+sharepoint_token

        uri = URI.parse(sharepoint_uri)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true if uri.scheme == 'https'

        response = http.start do
          request = Net::HTTP::Get.new(uri.request_uri,{'Authorization' => @auth})
          http.request(request)
        end
        JSON.parse(response.body)
      end

      def site_id
        @site_id ||= sharepoint_request("https://graph.microsoft.com/v1.0/sites/#{config[:domain]}:/sites/#{config[:site_name]}/")['id']
      end

      def drives
       @drives ||= sharepoint_request("https://graph.microsoft.com/v1.0/sites/#{site_id}/drives")['value']
     end

     def items_by_id(id)
       item = sharepoint_request("https://graph.microsoft.com/v1.0/sites/#{site_id}/drives/#{id}")
       item['value'].present? ? item['value'] : item
     end

     def download_url(file)
       file['@microsoft.graph.downloadUrl']
     end

    def sharepoint_client
      if token_expired?
        session = sharepoint_session
        register_access_token(sharepoint_session.get_access_token)
      end
    end

    def sharepoint_session
      authenticate
     end

    end
  end
end
