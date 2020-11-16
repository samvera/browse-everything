# frozen_string_literal: true

module BrowseEverythingHelper
  # Extracted from Rack::Mime 1.5.2 for use with earlier versions of Rack/Rails
  # @param [String] value
  # @param [String] matcher
  # @return [TrueClass,FalseClass]
  def mime_match?(value, matcher)
    v1, v2 = value.split('/', 2)
    m1, m2 = matcher.split('/', 2)
    return false if m1 != '*' && v1 != m1
    m2.nil? || m2 == '*' || m2 == v2
  end

  # @param [BrowseEverything::FileEntry] file
  # @return [TrueClass,FalseClass]
  def is_acceptable?(file)
    acceptable = params[:accept] || '*/*'
    acceptable_types = acceptable.split(/,\s*/)
    acceptable_types << 'application/x-directory'
    acceptable_types.any? { |type| mime_match?(file.type, type) }
  end

  def file_size_to_human_size(file_size)
    "#{file_size} bytes"
  end
end
