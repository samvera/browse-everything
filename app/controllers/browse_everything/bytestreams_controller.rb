# frozen_string_literal: true

module BrowseEverything
  class BytestreamsController < ActionController::Base
    include BrowseEverything::Controller::Authorizable
    skip_before_action :verify_authenticity_token

    def show
      decoded_id = CGI.unescape(id)
      decoded_id = decoded_id.gsub('&#x0002E;', '.')
      @bytestream = find_bytestream(id: decoded_id)
      # Refactor this
      raise ResourceNotFound if @bytestream.nil?
      @serialized = serialize(@bytestream)

      respond_to do |format|
        format.json_api { render json: @serialized }
      end
    rescue ResourceNotFound => not_found_error
      head(:not_found)
    end

    private
##

##

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
      delegate :find_bytestream, to: :driver

      def serialize(bytestream)
        # This option is needed given that any Object which responds to #size is assumed to be a collection
        serializer = BytestreamSerializer.new(bytestream, is_collection: false)
        serializer.serializable_hash
      end
  end
end
