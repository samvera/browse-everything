# frozen_string_literal: true

require 'rails'
require 'browse_everything/version'
require 'browse_everything/engine'
require 'browse_everything/retriever'

module BrowseEverything
  autoload :Browser,   'browse_everything/browser'
  autoload :FileEntry, 'browse_everything/file_entry'
  module Driver
    autoload :Base,        'browse_everything/driver/base'
    autoload :FileSystem,  'browse_everything/driver/file_system'
    autoload :Dropbox,     'browse_everything/driver/dropbox'
    autoload :Box,         'browse_everything/driver/box'
    autoload :GoogleDrive, 'browse_everything/driver/google_drive'
    autoload :S3,          'browse_everything/driver/s3'
  end
  module Auth
    module Google
      autoload :Credentials,        'browse_everything/auth/google/credentials'
      autoload :RequestParameters,  'browse_everything/auth/google/request_parameters'
    end
  end

  class InitializationError < RuntimeError; end
  class NotImplementedError < StandardError; end
  class NotAuthorizedError < StandardError; end

  class << self
    def configure(value)
      if value.nil? || value.is_a?(Hash)
        @config = value
      elsif value.is_a?(String)
        config_file_content = File.read(value)
        config_file_template = ERB.new(config_file_content)
        @config = YAML.safe_load(config_file_template.result)
        @config.deep_symbolize_keys!

        if @config.include? 'drop_box'
          warn '[DEPRECATION] `drop_box` is deprecated.  Please use `dropbox` instead.'
          @config['dropbox'] = @config.delete('drop_box')
        end
      else
        raise InitializationError, "Unrecognized configuration: #{value.inspect}"
      end
    end

    def config
      if @config.nil?
        config_path = Rails.root.join 'config', 'browse_everything_providers.yml'
        configure config_path.to_s
      end
      @config
    end
  end
end
