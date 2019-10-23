# frozen_string_literal: true
require 'jwt'

module BrowseEverything
  class ProvidersController < ActionController::Base
    skip_before_action :verify_authenticity_token

    def index
      @providers = Driver.all(host: request.host, port: request.port)
      @serializer = ProviderSerializer.new(@providers)
      respond_to do |format|
        format.json_api { render json: @serializer.serialized_json }
      end
    end

    def show
      @provider = current_provider
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
      build_attributes = if current_provider.externally_authorized?
                           authorization_attributes
                         else
                           {}
                         end
      @authorization = Authorization.build(**build_attributes)
      @authorization.save

      # Construct and return the JWT
      @json_web_token = build_json_web_token(@authorization)
      @auth_token = { authToken: @json_web_token }
      respond_to do |format|
        format.json do
          json_response = JSON.generate(@auth_token)
          render json: json_response
        end
        format.html { render 'browse_everything/authorize' }
      end
    end

    private

      def provider_params
        params.permit(:provider_id)
      end

      def provider_attributes
        values = { host: request.host, port: request.port, id: provider_params[:provider_id] }
        values.symbolize_keys
      end

      def current_provider
        Driver.build(**provider_attributes)
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
