# frozen_string_literal: true
class UploadSerializer
  include FastJsonapi::ObjectSerializer
  attributes :provider_id, :bytestream_ids, :container_ids

  has_one :provider
  has_many :bytestreams
  has_many :containers
end
