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

      def json_web_token
        return [] unless token_param

        @json_web_token ||= JWT.decode(token_param, nil, false)
      end

      # This method should be renamed
      def authorizations
        values = json_web_token.map { |payload| payload["data"] }
        values.compact
      end

      def authorization_ids
        authorizations.map { |authorization| authorization["id"] }
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
