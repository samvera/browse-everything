# frozen_string_literal: true
require 'signet/errors'
require 'google/apis/errors'
require 'jwt'

module BrowseEverything
  class ContainersController < ActionController::Base
    include BrowseEverything::Controller::Authorizable

    skip_before_action :verify_authenticity_token
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
      @container = find_container(id: id)
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
        results = Session.find_by(id: session_id)
        @session = results.first
        # This might be a security flaw
        if token_data.present?
          @session.authorization_ids += authorization_ids
        end
        @session
      end

      delegate :provider, to: :session
      delegate :find_container, :root_container, to: :provider

      # This is a work-around which might violate the JSON-API spec.
      # It may also simply be a bug in fast_json_api
      def serialize(container)
        serializer = ContainerSerializer.new(@container)
        serialized = serializer.serializable_hash
        if !container.bytestreams.empty?
          serialized_bytestreams = BytestreamSerializer.new(container.bytestreams)
          serialized[:data][:relationships][:bytestreams] = serialized_bytestreams.serializable_hash
        end
        if !container.containers.empty?
          serialized_containers = ContainerSerializer.new(container.containers)
          serialized[:data][:relationships][:containers] = serialized_containers.serializable_hash
        end

        JSON.generate(serialized)
      end
  end
end
