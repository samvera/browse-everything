# frozen_string_literal: true
require 'jwt'

module BrowseEverything
  class SessionsController < ActionController::Base
    skip_before_action :verify_authenticity_token
    before_action :validate_authorization_ids

    def create
      @session = Session.build(**session_attributes)
      @session.save
      @serializer = SessionSerializer.new(@session)
      respond_to do |format|
        format.json_api { render json: @serializer.serialized_json }
      end
    end

    def update
      @session = Session.find_by(id: session_id)

      @session.save
      @serializer = SessionSerializer.new(@session)
      respond_to do |format|
        format.json_api { render json: @serializer.serialized_json }
      end
    end

    private

      def json_api_request?
        mime_type = Mime::Type.lookup_by_extension(:json_api)
        request.content_type == mime_type.to_s
      end

      def json_api_params
        return unless json_api_request?

        payload = JSON.parse(request.body.string)
        ActionController::Parameters.new(payload)
      end

      def session_json_api_attributes
        data_params = json_api_params[:data]
        return unless data_params

        json_api_attributes = data_params[:attributes]
        json_api_attributes.permit(:provider_id)
      end

      def session_params
        params.permit(:provider_id)
      end

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

          authorizations = Authorization.where(id: authorization_id)
          authorization = authorizations.first
          !authorization.nil? && request_code == authorization.code
        end

        unless token_param && validations.reduce(:|)
          provider_id = session_attributes[:provider_id]
          # message = "Failed to validate the authorization token.  Please request the authorization using #{provider_authorize_url(provider_id)}"
          message = "Failed to validate the authorization token.  Please request a new authorization token."
          return head(:unauthorized, body: message)
        end
      end

      def session_attributes
        default_values = {
          host: request.host,
          port: request.port,
          authorization_ids: authorization_ids
        }
        new_session_attributes = session_params.empty? ? session_json_api_attributes : session_params
        values = default_values.merge(new_session_attributes.to_h)
        values.to_h.symbolize_keys
      end
  end
end
