# frozen_string_literal: true

module BrowseEverything
  class UploadFile < ApplicationRecord
    has_one_attached :bytestream
  end
end
