# frozen_string_literal: true

module BrowseEverything
  class UploadJob < ApplicationJob
    attr_reader :upload_id, :selected_bytestreams
    queue_as :default

    def selected_bytestream_ids
      selected_bytestreams.map(&:id)
    end

    def perform(upload_id:)
      @upload_id = upload_id
      @selected_bytestreams = []

      upload.container_ids.each do |container_id|
        upload_files = find_child_bytestreams(container_id)
        upload.file_ids += upload_files.map(&:id)
      end

      # Download the bytestreams
      upload.bytestream_ids.each do |bytestream_id|
        next if selected_bytestream_ids.include?(bytestream_id)

        bytestream = driver.find_bytestream(id: bytestream_id)
        persisted = create_upload_file(bytestream: bytestream)
        upload.file_ids << persisted.id
      end

      # Update the upload
      upload.processed = true
      upload.save
    end

    private

      def upload
        @upload ||= begin
                      uploads = Upload.find_by(uuid: upload_id)
                      uploads.first
                    end
      end
      delegate :session, to: :upload
      delegate :driver, :provider, to: :session
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

      # This should only be necessary for activestorage 0.1
      def mint_new_id
        last = UploadFile.last
        return 0 unless last

        last.id + 1
      end

      def create_upload_file(bytestream:)
        io = if bytestream.file_uri?
               file_path = bytestream.uri.gsub('file://', '')
               File.new(file_path)
             else
               build_download(bytestream.uri, request_headers)
             end

        upload_file = UploadFile.new(id: mint_new_id, name: bytestream.name)
        upload_file.bytestream.attach(io: io, filename: bytestream.name, content_type: bytestream.media_type)
        upload_file.save
        upload_file.reload
      end

      def find_child_bytestreams(container_id)
        persisted = []
        container = provider.find_container(id: container_id)

        container.bytestreams.each do |bytestream|
          next if selected_bytestream_ids.include?(bytestream.id)

          @selected_bytestreams << bytestream
          upload_file = create_upload_file(bytestream: bytestream)
          upload_file.container_id = container_id
          upload_file.save

          persisted << upload_file
        end

        container.containers.each do |child_container|
          persisted += find_child_bytestreams(child_container.id)
        end

        persisted
      end
  end
end
