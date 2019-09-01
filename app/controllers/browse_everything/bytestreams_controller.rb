# frozen_string_literal: true

module BrowseEverything
  class BytestreamsController < ActionController::Base
    skip_before_action :verify_authenticity_token

    def show
      find_or_initialize_by(**bytestream_attributes)
    end

    private

      def bytestream_attributes
        params.permit(:id)
      end

      def session_attributes
        params.require(:session).permit(:id)
      end

      def current_session
        # Sessions need to be implemented as ActiveRecord models to support this
        @current_session ||= Session.find_by(**session_attributes)
      end
      delegate :provider, to: :current_session

      def find_or_initialize_by(**attributes)
        provider.find_bytestream(**attributes)
      end
  end
end
