module BrowseEverything
  module Driver
    class Base
      attr_reader :config

      def initialize(config)
        @config = config
        validate_config
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