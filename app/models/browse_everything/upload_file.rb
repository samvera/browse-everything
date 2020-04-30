# frozen_string_literal: true

module BrowseEverything
  class UploadFile < ApplicationRecord
    self.table_name = 'browse_everything_upload_files'
    has_one_attached :bytestream

    def file_bytestream?
      file_path && File.exist?(file_path)
    end

    def download
      if file_bytestream?
        File.read(file_path)
      else
        bytestream.download
      end
    end

    def purge_bytestream
      bytestream&.purge
    end
  end
end
