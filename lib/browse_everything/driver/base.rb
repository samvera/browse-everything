# frozen_string_literal: true

module BrowseEverything
  module Driver
    # Abstract class for provider classes
    class Base
      include BrowseEverything::Engine.routes.url_helpers

      # Provide accessor and mutator methods for @token and @code
      attr_accessor :token, :code

      # Integrate sorting lambdas for configuration using initializers
      class << self
        attr_accessor :sorter

        # Provide a default sorting lambda
        # @return [Proc]
        def default_sorter
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

        # Set the sorter lambda (or proc) for all subclasses
        # (see Class.inherited)
        # @param subclass [Class] the class inheriting from BrowseEverything::Driver::Base
        def inherited(subclass)
          subclass.sorter = sorter
        end
      end

      # Constructor
      # @param config_values [Hash] configuration for the driver
      def initialize(config_values)
        @config = config_values
        @sorter = self.class.sorter || self.class.default_sorter
        validate_config
      end

      # Ensure that the configuration Hash has indifferent access
      # @return [ActiveSupport::HashWithIndifferentAccess]
      def config
        @config = ActiveSupport::HashWithIndifferentAccess.new(@config) if @config.is_a? Hash
        @config
      end

      # Abstract method
      def validate_config; end

      # Generate the key for the driver
      # @return [String]
      def key
        self.class.name.split(/::/).last.underscore
      end

      # Generate the icon markup for the driver
      # @return [String]
      def icon
        'unchecked'
      end

      # Generate the name for the driver
      # @return [String]
      def name
        @name ||= (@config[:name] || self.class.name.split(/::/).last.titleize)
      end

      # Abstract method
      def contents(_path = '', _page_index = 0)
        []
      end

      # Return the number of pages for the content entry list retrieved by the provider
      # Defaults to 0
      # @return [Integer]
      def contents_pages
        0
      end

      # Return the current page in the content entry list
      # Defaults to 0
      # @param [String] _ctx the context of the request
      # @return [Integer]
      def contents_current_page(_ctx)
        0
      end

      def contents_next_page(ctx)
        contents_current_page(ctx) + 1
      end

      def contents_last_page?(ctx)
        contents_current_page(ctx) == contents_pages
      end

      # Generate the link for a resource at a given path
      # @param path [String] the path to the resource
      # @return [Array<String, Hash>]
      def link_for(path)
        [path, { file_name: File.basename(path) }]
      end

      # Abstract method
      def authorized?
        false
      end

      # Abstract method
      def auth_link(*_args)
        []
      end

      # Abstract method
      def connect(*_args)
        nil
      end

      private

        # Generate the options for the Rails URL generation for API callbacks
        # remove the script_name parameter from the url_options since that is causing issues
        #   with the route not containing the engine path in rails 4.2.0
        # @return [Hash]
        def callback_options
          options = config.to_hash
          options.deep_symbolize_keys!
          options[:url_options].reject { |k, _v| k == :script_name }
        end

        # Generate the URL for the API callback
        # @return [String]
        def callback
          connector_response_url(callback_options)
        end
    end
  end
end
