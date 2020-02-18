# frozen_string_literal: true

class UploadFile < ApplicationRecord
  has_one_attached :bytestream
end
