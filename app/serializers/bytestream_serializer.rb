# frozen_string_literal: true
class BytestreamSerializer
  include FastJsonapi::ObjectSerializer
  attributes :location, :name, :size, :mtime, :media_type

  belongs_to :container
end
