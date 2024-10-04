# frozen_string_literal: true

module BrowseEverything
  class AuthorizationsController < ActionController::Base
    include BrowseEverything::Controller::JsonRequestable

    skip_before_action :verify_authenticity_token if respond_to?(:verify_authenticity_token)

    # This should be the action which handles OAuth2 callbacks
    # OAuth2 cannot transmit a POST request in response to a successful
    # authorization
    # @see SessionsController#authorize
    #
    def show
      authorizations = Authorization.find_by(uuid: id)
      raise ResourceNotFound if authorizations.empty?

      @authorization = authorizations.first

      @serializer = AuthorizationSerializer.new(@authorization)

      respond_to do |format|
        format.json_api { render json: @serializer.serialized_json }
      end
    rescue ResourceNotFound => e
      head(:not_found)
    end

    def update
      authorizations = Authorization.find_by(uuid: id)
      raise ResourceNotFound if authorizations.empty?

      authorization = authorizations.first
      @authorization = authorization.update(**authorization_attributes)
      @authorization.save

      @serializer = AuthorizationSerializer.new(@authorization)
      serialized_json = @serializer.serialized_json
      serialized = JSON.parse(serialized_json)
      # I do not know why this is happening
      serialized['data']['code'] = @authorization.code
      serialized_response = JSON.generate(serialized)

      respond_to do |format|
        format.json_api { render json: serialized_response }
      end
    rescue ResourceNotFound => e
      head(:not_found)
    end

    def destroy
      authorizations = Authorization.find_by(uuid: id)
      raise ResourceNotFound if authorizations.empty?

      @authorization = authorizations.first
      @authorization.destroy
      head(:success)
    rescue ResourceNotFound => e
      head(:not_found)
    end

    private

      def id
        params[:id]
      end

      def authorization_json_api_attributes
        json_api_attributes = resource_json_api_attributes
        return unless json_api_attributes

        json_api_attributes.permit(:code)
      end

      def authorization_params
        params.permit(:code)
      end

      def authorization_attributes
        new_authorization_attributes = authorization_params.empty? ? authorization_json_api_attributes : authorization_params
        new_authorization_attributes.to_h.symbolize_keys
      end
  end
end
