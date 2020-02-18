# frozen_string_literal: true

require 'jwt'

module BrowseEverything
  class SessionsController < ActionController::Base
    include BrowseEverything::Controller::JsonApiRequestable
    include BrowseEverything::Controller::Authorizable

    skip_before_action :verify_authenticity_token
    before_action :validate_authorization_ids

    def create
      @session = Session.build(**session_attributes)
      @session.save
      @serializer = SessionSerializer.new(@session)
      respond_to do |format|
        format.json_api { render status: :created, json: @serializer.serialized_json }
      end
    end

    def index
      @sessions = Session.all

      @serializer = SessionSerializer.new(@sessions)
      respond_to do |format|
        format.json_api { render json: @serializer.serialized_json }
      end
    end

    def show
      sessions = Session.find_by(uuid: id)
      @session = sessions.first
      # Refactor this
      raise ResourceNotFound if @session.nil?

      @session.save
      @serializer = SessionSerializer.new(@session)
      respond_to do |format|
        format.json_api { render json: @serializer.serialized_json }
      end
    rescue ResourceNotFound => not_found_error
      head(:not_found)
    end

    def destroy
      sessions = Session.find_by(uuid: id)
      @session = sessions.first
      # Refactor this
      raise ResourceNotFound if @session.nil?

      @session.destroy
      head(:success)
    rescue ResourceNotFound => not_found_error
      head(:not_found)
    end

    private

      def id
        params[:id]
      end

      def session_json_api_attributes
        json_api_attributes = resource_json_api_attributes
        return unless json_api_attributes

        json_api_attributes.permit(:provider_id)
      end

      def session_params
        params.permit(:provider_id)
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
