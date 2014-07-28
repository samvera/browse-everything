module BrowseEverything
  module Driver
    class Base
      include BrowseEverything::Engine.routes.url_helpers

      attr_reader :config, :name
      attr_accessor :token
      
      def initialize(config,session_info={})
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

      def contents(path)
        []
      end

      def details(path)
        nil
      end

      def link_for(path)
        [path, { file_name: File.basename(path) }]
      end

      def authorized?
        false
      end

      def auth_link
        []
      end

      def connect(params,data)
        nil
      end

    end
  end
end
