# frozen_string_literal: true
require 'signet/errors'
require 'google/apis/errors'
require 'jwt'

module BrowseEverything
  class ContainersController < ActionController::Base
    include BrowseEverything::Controller::Authorizable

    skip_before_action :verify_authenticity_token
    # This should not need to be disabled
    # before_action :validate_authorization_ids

    def index
      @container = root_container
      @serialized = serialize(root_container)

      respond_to do |format|
        format.json_api { render json: @serialized }
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
      decoded_id = CGI.unescape(id)
      decoded_id = decoded_id.gsub('&#x0002E;', '.')
      @container = find_container(id: decoded_id)
      @serialized = serialize(@container)

      respond_to do |format|
        format.json_api { render json: @serialized }
      end
    end

    private

      def id
        params[:id]
      end

      def session_id
        params[:session_id]
      end

      def session
        return @session unless @session.nil?

        # This should follow the query_service#find_by pattern
        results = Session.find_by(uuid: session_id)
        @session = results.first
        # Add the authorization tokens from the JWT
        @session.authorization_ids += authorization_ids if token_data.present?
        @session
      end

      delegate :driver, to: :session
      delegate :find_container, :root_container, to: :driver

      # This is a work-around which might violate the JSON-API spec.
      # It may also simply be a bug in fast_json_api
      def serialize(container)
        serializer = ContainerSerializer.new(@container)
        serialized = serializer.serializable_hash
        unless container.bytestreams.empty?
          serialized_bytestreams = BytestreamSerializer.new(container.bytestreams)
          serialized[:data][:relationships][:bytestreams] = serialized_bytestreams.serializable_hash
        end
        unless container.containers.empty?
          serialized_containers = ContainerSerializer.new(container.containers)
          serialized[:data][:relationships][:containers] = serialized_containers.serializable_hash
        end

        JSON.generate(serialized)
      end
  end
end
