# frozen_string_literal: true
require 'jwt'

module BrowseEverything
  class ProvidersController < ActionController::Base
    skip_before_action :verify_authenticity_token

    def index
      @providers = Provider.all(host: request.host, port: request.port)
      @serializer = ProviderSerializer.new(@providers)
      respond_to do |format|
        format.json_api { render json: @serializer.serialized_json }
      end
    end

    def show
      @provider = Provider.build(**provider_attributes)
      @serializer = ProviderSerializer.new(@provider)
      respond_to do |format|
        format.json { render json: @serializer.serialized_json }
      end
    end

    # This creates a new authorization, persists the authorization, uses this to
    # generate a new JSON Web Token
    # The persisted authorization is used to validate the JSON Web Token
    # transmitted in requests
    def authorize
      @authorization = Authorization.build(**authorization_attributes)
      @authorization.save

      # Construct and return the JWT
      @json_web_token = build_json_web_token(@authorization)
      @auth_token = { authToken: @json_web_token }
      respond_to do |format|
        format.json { render json: json_response }
        format.html { render 'browse_everything/authorize' }
      end
    end

    private

      def provider_params
        params.permit(:id)
      end

      def provider_attributes
        default_values = { host: request.host, port: request.port }
        values = default_values.merge(provider_params)
        values.to_h.symbolize_keys
      end

      def authorization_params
        params.permit(:code)
      end

      def authorization_attributes
        values = authorization_params
        values.to_h.symbolize_keys
      end

      # Build the JSON Web Token
      # @param [Authorization] authorization
      # @return [String] the JSON Web Token
      # @todo This should be refactored to be used between Controllers
      def build_json_web_token(authorization)
        payload = {
          data: authorization.serializable_hash
        }

        JWT.encode(payload, nil, 'none')
      end
  end
end
