class UploadFile < ApplicationRecord
  has_one_attached :download
end
