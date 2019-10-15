class UploadFile < ApplicationRecord
  has_one_attached :bytestream
end
