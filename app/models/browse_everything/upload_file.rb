# frozen_string_literal: true

module BrowseEverything
  class UploadFile < ApplicationRecord
    self.table_name = 'browse_everything_upload_files'
    has_one_attached :bytestream
  end
end
