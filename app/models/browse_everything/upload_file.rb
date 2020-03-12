# frozen_string_literal: true

class BrowseEverything::UploadFile < ApplicationRecord
  has_one_attached :bytestream
end
