module BrowseEverything
  module Driver
    class Base
      attr_reader :config

      def initialize(config)
        @config = config
        validate_config
      end

      def icon
        'unchecked'
      end

      def name
        self.class.name.split(/::/).last.titleize
      end

      def validate_config
      end

      def contents(path)
        []
      end

      def details(path)
        {}
      end
    end
  end
end