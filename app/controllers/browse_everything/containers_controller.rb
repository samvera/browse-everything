# frozen_string_literal: true
require 'signet/errors'
require 'google/apis/errors'
require 'jwt'

module BrowseEverything
  class ContainersController < ActionController::Base
    skip_before_action :verify_authenticity_token

    def index
      @container = root_container
      @serializer = ContainerSerializer.new(@container)

      respond_to do |format|
        format.json { render json: @serializer.serialized_json }
      end
    rescue Signet::AuthorizationError => authorization_error
      # Retrieve and destroy the most recent authorization (as it is invalid)
      last_authorization_id = session.authorization_ids.pop

      # This should follow the query_service#find_by pattern
      authorizations = Authorization.find_by(id: last_authorization_id)
      unless authorizations.empty?
        authorization = authorizations.first
        authorization.destroy
      end

      # Update the Session
      session.save
      head(:forbidden, body: authorization_error.message)
    rescue Google::Apis::ClientError => client_error
      head(:unauthorized, body: client_error.message)
    rescue StandardError => error
      head(:unauthorized, body: error.message)
    end

    def show
      @container = find_container(id: id)
      @serializer = ContainerSerializer.new(@container)

      respond_to do |format|
        format.json { render json: @serializer.serialized_json }
      end
    end

    private

      def id
        params[:id]
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

      def session_id
        params[:session_id]
      end

      def session
        return @session unless @session.nil?

        # This should follow the query_service#find_by pattern
        results = Session.find_by(id: session_id)
        @session = results.first
        if token_param.present?
          @session.authorization_ids += authorization_ids
        end
        @session
      end

      delegate :provider, to: :session
      delegate :find_container, :root_container, to: :provider
  end
end
