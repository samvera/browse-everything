# frozen_string_literal: true

module BrowseEverything
  class UploadsController < ActionController::Base
    include BrowseEverything::Controller::JsonApiRequestable
    include BrowseEverything::Controller::Authorizable

    skip_before_action :verify_authenticity_token if respond_to?(:verify_authenticity_token)
    before_action :validate_authorization_ids

    def create
      upload = Upload.build(**upload_attributes)

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
      upload.save
      @serializer = UploadSerializer.new(upload)

      # This will be the job which asynchronously downloads the files in
      # ActiveStorage Models
      upload_job = upload.job
      upload_job.perform_now
      respond_to do |format|
        format.json_api { render status: :created, json: @serializer.serialized_json }
      end
    end

    def index
      @uploads = Upload.all

      @serializer = UploadSerializer.new(@uploads)
      respond_to do |format|
        format.json_api { render json: @serializer.serialized_json }
      end
    end

    def show
      uploads = Upload.find_by(uuid: upload_id)
      raise ResourceNotFound if uploads.empty?

      @upload = uploads.first
      @serializer = UploadSerializer.new(@upload)
      respond_to do |format|
        format.json_api { render json: @serializer.serialized_json }
      end
    rescue ResourceNotFound => e
      head(:not_found)
    end

    def destroy
      uploads = Upload.find_by(uuid: upload_id)
      raise ResourceNotFound if uploads.empty?

      @upload = uploads.first
      @upload.destroy
      head(:success)
    rescue ResourceNotFound => e
      head(:not_found)
    end

    private

      def upload_json_api_attributes
        json_api_attributes = resource_json_api_attributes
        return unless json_api_attributes

        # This requires that we receive the files twice, which could be
        # problematic
        # However, we will ultimately need to download them with a second
        # request

        # This is another bug, I'm not sure why this is not being handled
        # json_api_attributes.permit(:session_id, :bytestream_ids, :container_ids)
        values = {}
        new_params = json_api_params.require(:data).require(:attributes)
        values[:session_id] = new_params.require(:session_id)
        values[:bytestream_ids] = new_params.require(:bytestream_ids) if new_params.include?(:bytestream_ids) && new_params[:bytestream_ids].present?
        values[:container_ids] = new_params.require(:container_ids) if new_params.include?(:container_ids) && new_params[:container_ids].present?
        values
      end

      def upload_params
        params.permit(:session_id, :bytestream_ids, :container_ids)
      end

      def upload_id
        params[:id]
      end

      def upload_attributes
        new_upload_attributes = if upload_params.empty?
                                  upload_json_api_attributes
                                else
                                  upload_params
                                end
        new_upload_attributes.to_h.symbolize_keys
      end
  end
end
