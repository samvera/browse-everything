# frozen_string_literal: true
require 'jwt'

module BrowseEverything
  module Controller
    module Authorizable
      extend ActiveSupport::Concern

      private

        def token_param
          params[:token] || json_api_params[:token]
        end

        def token_header
          auth_header = headers['Authorization']
          return unless auth_header

          auth_header.sub('Bearer ', '')
        end

        def token_data
          token_header || token_param
        end

        # Decode the JSON Web Tokens transmitted in the request
        # @return [Array<String>] the set of JWTs
        def json_web_tokens
          return [] unless token_data

          @json_web_tokens ||= JWT.decode(token_data, nil, false)
        end

        # @return [Array<Hash>] the set of serialized Authorizations transmitted
        # in the JWT
        def authorization_data
          return @authorization_data unless @authorization_data.nil?

          values = json_web_tokens.map { |payload| payload["data"] }
          @authorization_data = values.compact
        end

        def authorization_ids
          @authorization_ids ||= authorization_data.map { |authorization| authorization["id"] }
        end

        # Validate that each JSON Web Token references an Authorization which
        # has been serialized in the database
        # @return [Boolean]
        # @todo This needs to be refactored into a Concern for usage in other
        # Controllers
        def validate_authorization_ids
          validations = authorization_data.map do |data|
            authorization_id = data["id"]
            request_code = data["code"]

            authorizations = BrowseEverything::Authorization.where(uuid: authorization_id)
            authorization = authorizations.first
            !authorization.nil? && request_code == authorization.code
          end

          # There is token data and it is valid
          return if token_data && validations.reduce(:|)

          message = "Failed to validate the authorization token.  Please request a new authorization token."
          head(:unauthorized, body: message)
        end
    end
  end
end
