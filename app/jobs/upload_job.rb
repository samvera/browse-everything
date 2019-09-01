
class UploadJob < ApplicationJob
  attr_reader: :upload_id
  queue_as :default

  after_perform :destroy_sessions, :destroy_upload

  def perform(upload_id:)
    @upload_id = upload_id

    upload.bytestreams.each do |bytestream|
      # Do something like download the files here
    end

    upload.containers.each do |containers|
      # Iterate through the container bytestreams and download the files here
    end

    updated_upload_jobs = upload.session.pending_upload_jobs.delete_if { |job| job.upload_id == upload_id }
    upload.session.pending_upload_jobs = updated_upload_jobs
    upload.session.save
  end

  private

    def upload
      @upload ||= Upload.find_by(id: upload_id)
    end

    def destroy_sessions
      if upload.session.pending_upload_jobs.empty?
        upload.session.destroy
      end
    end

    def destroy_upload
      upload.destroy
    end
end
