# frozen_string_literal: true

require 'rails'
require 'browse_everything/version'
require 'browse_everything/engine'
require 'browse_everything/retriever'
require 'fast_jsonapi'

module BrowseEverything
  module Auth
    module Google
      # The credentials are still needed
      autoload :Credentials,        'browse_everything/auth/google/credentials'
      autoload :RequestParameters,  'browse_everything/auth/google/request_parameters'
    end
  end

  autoload :Browser,   'browse_everything/browser'
  autoload :FileEntry, 'browse_everything/file_entry'

  autoload :Bytestream, 'browse_everything/bytestream'
  autoload :Container, 'browse_everything/container'
  autoload :Authorization, 'browse_everything/authorization'
  autoload :Session, 'browse_everything/session'
  autoload :Upload, 'browse_everything/upload'

  autoload :Driver, 'browse_everything/driver'
  autoload :FileSystem, 'browse_everything/driver/file_system'
  autoload :GoogleDrive, 'browse_everything/driver/google_drive'

  module Auth
    module Google
      autoload :Credentials,        'browse_everything/auth/google/credentials'
      autoload :RequestParameters,  'browse_everything/auth/google/request_parameters'
    end
  end

  class InitializationError < RuntimeError; end
  class ConfigurationError < StandardError; end
  class NotImplementedError < StandardError; end
  class NotAuthorizedError < StandardError; end

  class Configuration < OpenStruct; end

  class << self
    attr_writer :config

    def default_config_file_path
      Rails.root.join('config', 'browse_everything_providers.yml')
    end

    def parse_config_file(path)
      config_file_content = File.read(path)
      config_file_template = ERB.new(config_file_content)
      config_values = YAML.safe_load(config_file_template.result, [Symbol])
      @config = Configuration.new(config_values.deep_symbolize_keys)
    rescue Errno::ENOENT
      raise ConfigurationError, 'Missing browse_everything_providers.yml configuration file'
    end

    def configure(values = {})
      if value.is_a?(Hash)
        @config = ActiveSupport::HashWithIndifferentAccess.new value
        @config = Configuration.new(values)
      elsif value.is_a?(String)
        # There should be a deprecation warning issued here
        parse_config_file(values)
      else
        raise InitializationError, "Unrecognized configuration: #{value.inspect}"
      end

      if @config.include? 'drop_box' # rubocop:disable Style/GuardClause
        warn '[DEPRECATION] `drop_box` is deprecated.  Please use `dropbox` instead.'
        @config['dropbox'] = @config.delete('drop_box')
      end
    end

    def config
      @config ||= parse_config_file(default_config_file_path)
    end
  end
end
