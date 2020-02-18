# frozen_string_literal: true

class UploadJob < ApplicationJob
  attr_reader :upload_id
  queue_as :default

  def perform(upload_id:)
    @upload_id = upload_id

    # Download the containers
    upload.container_ids.each do |container_id|
      container = provider.find_container(id: container_id)
      # @todo Fix the _bytestream
      container.bytestreams.each do |_bytestream|
        retrieved_bytestream = provider.find_bytestream(id: bytestream_id)
        persisted = create_upload_file(bytestream: retrieved_bytestream)
        upload.file_ids << persisted.id
      end
    end

    # Download the bytestreams
    upload.bytestream_ids.each do |bytestream_id|
      bytestream = driver.find_bytestream(id: bytestream_id)
      persisted = create_upload_file(bytestream: bytestream)
      upload.file_ids << persisted.id
    end

    # Update the upload
    upload.save
  end

  private

    def upload
      @upload ||= begin
                    uploads = BrowseEverything::Upload.find_by(uuid: upload_id)
                    uploads.first
                  end
    end

    def session
      return if upload.nil? || upload.session_id.blank?

      @session ||= begin
                    sessions = BrowseEverything::Session.find_by(uuid: upload.session_id)
                    sessions.first
                  end
    end

    delegate :driver, to: :session
    delegate :auth_token, to: :driver

    def request_headers
      return {} unless auth_token

      {
        'Authorization' => "Bearer #{auth_token}"
      }
    end

    def build_download(url, headers)
      response = Typhoeus.get(url, headers: headers)
      StringIO.new(response.body)
    end

    def create_upload_file(bytestream:)
      io = if bytestream.file_uri?
             file_path = bytestream.location.gsub('file://', '')
             File.new(file_path)
           else
             build_download(bytestream.uri, request_headers)
           end
      upload_file = UploadFile.new
      upload_file.bytestream.attach(io: io, filename: bytestream.name, content_type: bytestream.media_type)
      upload_file.save
      upload_file.reload
    end
end
