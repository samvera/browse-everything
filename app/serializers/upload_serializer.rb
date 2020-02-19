# frozen_string_literal: true

class UploadSerializer
  include FastJsonapi::ObjectSerializer
  attributes :session_id, :bytestream_ids, :container_ids

  has_one :session
  has_many :bytestreams
  has_many :containers
end
