require 'googleauth'

# Object structuring the credentials retrieved for the Google API's
module BrowseEverything
  module Auth
    module Google
      class Credentials < ::Google::Auth::UserRefreshCredentials
        # Ensures that every call to retrieve an access token does *not* require an HTTP request
        # @see Google::Auth::UserRefreshCredentials#fetch_access_token
        # @param options [Hash] the access token values
        def fetch_access_token(options = {})
          return build_token_hash if access_token
          super(options)
        end

        private

          # Structure a hash from existing access token values (usually cached within a Cookie)
          # @return [Hash]
          def build_token_hash
            { 'access_token' => access_token }
          end
      end
    end
  end
end
