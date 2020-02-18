# frozen_string_literal: true

module BrowseEverything
  class AuthorizationsController < ActionController::Base
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
  end
end
