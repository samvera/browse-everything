# frozen_string_literal: true
require 'jwt'

module BrowseEverything
  class SessionsController < ActionController::Base
    skip_before_action :verify_authenticity_token

    def create
      @session = Session.build(**session_attributes)
      @session.save
      @serializer = SessionSerializer.new(@session)
      respond_to do |format|
        format.json { render json: @serializer.serialized_json }
      end
    end

    def update
      @session = Session.find_by(id: session_id)

      @session.save
      @serializer = SessionSerializer.new(@session)
      respond_to do |format|
        format.json { render json: @serializer.serialized_json }
      end
    end

    private

      def session_params
        params.permit(:provider_id)
      end

      def token_param
        params[:token]
      end

      # Decode the JSON Web Tokens transmitted in the request
      # @return [Array<String>] the set of JWTs
      def json_web_tokens
        return [] unless token_param

        @json_web_tokens ||= JWT.decode(token_param, nil, false)
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

          authorization = Authorization.find(id: authorization_id)
          !authorization.nil? && request_code == authorization.code
        end
        validations.reduce(:|)
      end

      def session_attributes
        default_values = {
          host: request.host,
          port: request.port,
          authorization_ids: authorization_ids
        }
        values = default_values.merge(session_params)
        values.to_h.symbolize_keys
      end
  end
end
