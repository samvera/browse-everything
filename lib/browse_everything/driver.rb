# frozen_string_literal: true
require 'google/apis/drive_v3'
require 'googleauth'
require 'googleauth/stores/file_token_store'
require_relative 'driver/file_system'
require_relative 'driver/google_drive'

module BrowseEverything
  class Driver
    include BrowseEverything::Engine.routes.url_helpers

    attr_accessor :auth_code

    def self.driver_class_for(driver_name)
      "BrowseEverything::Driver::#{driver_name.camelize}".constantize
    rescue NameError
      Rails.logger.warn("Driver #{driver_name} is not supported in BrowseEverything")
      self
    end

    def self.build(id:, auth_code: nil, host: 'http://localhost', port: 80)
      driver_class = driver_class_for(id)
      driver_class.new(auth_code: auth_code, host: host, port: port)
    end

    def self.config
      BrowseEverything.config
    end

    def self.all(host: 'http://localhost', port: 80)
      config.to_h.map do |key, _value|
        build(id: key.to_s, host: host, port: port)
      end
    end

    def initialize(auth_code: nil, host: 'http://localhost', port: 80)
      @auth_code = auth_code
      @host = host
      @port = port
    end

    def name
      namespaced_name = self.class.name
      last_segment = namespaced_name.split('::').last.underscore.humanize
      last_segment.gsub(/\s(.)/) { " #{Regexp.last_match(1).capitalize}" }
    end

    def id
      namespaced_name = self.class.name.underscore
      namespaced_name.split('/').last
    end

    def config
      self.class.config[id.to_sym]
    end

    def default_callback_options
      {
        provider_id: id,
        host: @host,
        port: @port
      }
    end

    # Generate the options for the Rails URL generation for API callbacks
    # remove the script_name parameter from the url_options since that is causing issues
    #   with the route not containing the engine path in rails 4.2.0
    # @return [Hash]
    def callback_options
      options = if config[:url_options]
                  config[:url_options].reject { |k, _v| k == :script_name }
                else
                  {}
                end

      options.merge(default_callback_options)
    end

    # Generate the URL for the API callback
    # Note: this is tied to the routes used for the OAuth callbacks
    # @return [String]
    def callback
      connector_response_url(callback_options)
    end

    def authorization_url
      nil
    end

    def externally_authorized?
      !authorization_url.nil?
    end

    def auth_token
      nil
    end
  end
end
