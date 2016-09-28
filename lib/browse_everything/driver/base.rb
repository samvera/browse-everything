module BrowseEverything
  module Driver
    class Base
      include BrowseEverything::Engine.routes.url_helpers

      attr_reader :config, :name
      attr_accessor :token

      def initialize(config, _session_info = {})
        @config = config
        validate_config
      end

      def key
        self.class.name.split(/::/).last.underscore
      end

      def icon
        'unchecked'
      end

      def name
        @name ||= (@config[:name] || self.class.name.split(/::/).last.titleize)
      end

      def validate_config
      end

      def contents(_path)
        []
      end

      def details(_path)
        nil
      end

      def link_for(path)
        [path, { file_name: File.basename(path) }]
      end

      def authorized?
        false
      end

      # @return [Array{URI,Object}] 2 elements: the URI, and session data to store under "#{provider_name}_data"
      def auth_link
        []
      end

      def connect(_params, _data)
        nil
      end

      private

        def callback
          connector_response_url(callback_options)
        end

        # remove the script_name parameter from the url_options since that is causing issues
        #   with the route not containing the engine path in rails 4.2.0
        def callback_options
          config[:url_options].reject { |k, _v| k == :script_name }
        end
    end
  end
end
