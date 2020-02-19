# frozen_string_literal: true

module BrowseEverything
  module Driver
    # Class for instantiating authentication API Objects
    class AuthenticationFactory
      # Constructor
      # @param klass [Class] the authentication object class
      # @param params [Array, Hash] the parameters for the authentication constructor
      def initialize(klass, *params)
        @klass = klass
        @params = params
      end

      # Constructs an authentication Object
      # @return [Object]
      def authenticate
        @klass.new(*@params)
      end
    end
  end
end
