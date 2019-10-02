# frozen_string_literal: true

module BrowseEverything
  class UploadsController < ActionController::Base
    include BrowseEverything::Controller::JsonApiRequestable
    include BrowseEverything::Controller::Authorizable

    skip_before_action :verify_authenticity_token
    before_action :validate_authorization_ids

    def create
      @upload = Upload.build(**upload_attributes)

      # Before the Upload is fully serialized, here each selected bytestream and
      # container needs to be downloaded using the asynchronous job
      #
      # This will need to be a future feature in order to handle cases where the
      # auth. code simply expires or other failures are encountered
      #
      # The better approach here is going to be to load serialized Bytestreams
      # and Containers from the POST parameters
      # This ensures that there won't be any failures during the upload sequence
      #
      # There is still the possibility that downloads will fail, but this was
      # always the case
      @upload.save

      # This will be the job which asynchronously downloads the files in
      # ActiveStorage Models
      job.perform_now

      @serializer = UploadSerializer.new(@upload)
      respond_to do |format|
        format.json_api { render json: @serializer.serialized_json }
      end
    end

    def show
      @upload = Upload.find_by(id: upload_id)
      @serializer = UploadSerializer.new(@upload)
      respond_to do |format|
        format.json_api { render json: @serializer.serialized_json }
      end
    end

    private

      def upload_json_api_attributes
        json_api_attributes = resource_json_api_attributes
        return unless json_api_attributes

        json_api_attributes.permit(:session_id, :bytestream_ids, :container_ids)
      end

      def upload_params
        params.permit(:session_id, :bytestream_ids, :container_ids)
      end

      def upload_id
        params[:id]
      end

      def upload_attributes
        new_upload_attributes = upload_params.empty? ? upload_json_api_attributes : upload_params
        values = default_values.merge(new_upload_attributes.to_h)
        values.to_h.symbolize_keys
      end
  end
end
