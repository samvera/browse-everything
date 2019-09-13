# frozen_string_literal: true

module BrowseEverything
  class AuthorizationsController < ActionController::Base
    # This should be the action which handles OAuth2 callbacks
    # OAuth2 cannot transmit a POST request in response to a successful
    # authorization
    # @see SessionsController#authorize
    #
    # For consistency, clients should still be able to create authorizations
    # manually
    def create; end

    def show
      @authorization = Authorization.new(**authorization_attributes)
      # This is an anti-pattern; I'm not certain how to reconcile this without
      # persisting the resource using ActiveRecord and instead using #create
      @authorization.store_session_values
      @serializer = AuthorizationSerializer.new(@authorization)

      respond_to do |format|
        format.json { render json: @serializer.serialized_json }
      end
    end

    private

      def authorization_params
        params.permit(:code)
      end

      def authorization_attributes
        authorization_params.merge(session: session)
      end
  end
end
