# frozen_string_literal: true

require 'rails'
require 'browse_everything/version'
require 'browse_everything/engine'
require 'browse_everything/retriever'

module BrowseEverything
  autoload :Browser,   'browse_everything/browser'
  autoload :FileEntry, 'browse_everything/file_entry'

  module Driver
    module Paginator
      autoload :Base,         'browse_everything/driver/paginator/base'
      autoload :GoogleDrive,  'browse_everything/driver/paginator/google_drive'
    end

    autoload :Base,        'browse_everything/driver/base'
    autoload :FileSystem,  'browse_everything/driver/file_system'
    autoload :Dropbox,     'browse_everything/driver/dropbox'
    autoload :Box,         'browse_everything/driver/box'
    autoload :GoogleDrive, 'browse_everything/driver/google_drive'
    autoload :S3,          'browse_everything/driver/s3'

    # Access the sorter set for the base driver class
    # @return [Proc]
    def sorter
      BrowseEverything::Driver::Base.sorter
    end

    # Provide a custom sorter for all driver classes
    # @param [Proc] the sorting lambda (or proc)
    def sorter=(sorting_proc)
      BrowseEverything::Driver::Base.sorter = sorting_proc
    end

    module_function :sorter, :sorter=
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
    attr_writer :config

    def configure(value)
      return if value.nil?
      if value.is_a?(Hash)
        @config = ActiveSupport::HashWithIndifferentAccess.new value
      elsif value.is_a?(String)
        config_file_content = File.read(value)
        config_file_template = ERB.new(config_file_content)
        config_values = YAML.safe_load(config_file_template.result, [Symbol])
        @config = ActiveSupport::HashWithIndifferentAccess.new config_values
        @config.deep_symbolize_keys
      else
        raise InitializationError, "Unrecognized configuration: #{value.inspect}"
      end

      if @config.include? 'drop_box' # rubocop:disable Style/GuardClause
        warn '[DEPRECATION] `drop_box` is deprecated.  Please use `dropbox` instead.'
        @config['dropbox'] = @config.delete('drop_box')
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
