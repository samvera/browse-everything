# frozen_string_literal: true

module BrowseEverything
  module V1
    module Driver
      class Base
        include BrowseEverything::Engine.routes.url_helpers

        # Provide accessor and mutator methods for @token and @code
        attr_accessor :token, :code

        # Integrate sorting lambdas for configuration using initializers
        attr_accessor :sorter

        def self.default_sorter
          lambda { |files|
            files.sort do |a, b|
              if b.container?
                a.container? ? a.name.downcase <=> b.name.downcase : 1
              else
                a.container? ? -1 : a.name.downcase <=> b.name.downcase
              end
            end
          }
        end

        def initialize(config_values)
          @config = config_values
          @sorter = self.class.default_sorter
          validate_config
        end

        def config
          @config = ActiveSupport::HashWithIndifferentAccess.new(@config) if @config.is_a? Hash
          @config
        end

        def validate_config; end

        def key
          self.class.name.split(/::/).last.underscore
        end

        def icon
          'unchecked'
        end

        def name
          @name ||= (@config[:name] || self.class.name.split(/::/).last.titleize)
        end

        def contents(*_args)
          []
        end

        def link_for(path)
          [path, { file_name: File.basename(path) }]
        end

        def authorized?
          false
        end

        def auth_link(*_args)
          []
        end

        def connect(*_args)
          nil
        end

        private

          def callback_options
            options = config.to_hash
            options.deep_symbolize_keys!
            options[:url_options].reject { |k, _v| k == :script_name }
          end

          def callback
            connector_response_url(callback_options)
          end
      end
    end
  end
end
