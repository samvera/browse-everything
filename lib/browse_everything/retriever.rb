# frozen_string_literal: true

require 'addressable'
require 'tempfile'
require 'typhoeus'

module BrowseEverything
  # Class for raising errors when a download is invalid
  class DownloadError < StandardError
    attr_reader :response

    # Constructor
    # @param msg [String]
    # @param response [Typhoeus::Response] response from the server
    def initialize(msg, response)
      @response = response
      super(msg)
    end

    # Generate the message for the exception
    # @return [String]
    def message
      "#{super}: #{response.body}"
    end
  end

  # Class for retrieving a file or resource from a storage provider
  class Retriever
    CHUNK_SIZE = 16384

    attr_accessor :chunk_size

    class << self
      def can_retrieve?(uri)
        Typhoeus.get(uri, headers: { Range: 'bytes=0-0' }).success?
      end
    end

    # Constructor
    def initialize
      @chunk_size = CHUNK_SIZE
    end

    # Download a file or resource
    # @param options [Hash]
    # @param target [String, nil] system path to the downloaded file (defaults to a temporary file)
    def download(spec, target = nil)
      if target.nil?
        ext = File.extname(spec['file_name'])
        base = File.basename(spec['file_name'], ext)
        target = Dir::Tmpname.create([base, ext]) {}
      end

      File.open(target, 'wb') do |output|
        retrieve(spec) do |chunk, retrieved, total|
          output.write(chunk)
          yield(target, retrieved, total) if block_given?
        end
      end
      target
    end

    # Retrieve the resource from the storage service
    # @param options [Hash]
    def retrieve(options, &block)
      expiry_time_value = options.fetch('expires', nil)
      if expiry_time_value
        expiry_time = Time.parse(expiry_time_value)
        raise ArgumentError, "Download expired at #{expiry_time}" if expiry_time < Time.now
      end

      download_options = extract_download_options(options)
      url = download_options[:url]

      case url.scheme
      when 'file'
        retrieve_file(download_options, &block)
      when /https?/
        retrieve_http(download_options, &block)
      else
        raise URI::BadURIError, "Unknown URI scheme: #{url.scheme}"
      end
    end

    private

      # Extract and parse options used to download a file or resource from an HTTP API
      # @param options [Hash]
      # @return [Hash]
      def extract_download_options(options)
        url = options.fetch('url')

        # This avoids the potential for a KeyError
        headers = options.fetch('headers', {}) || {}

        file_size_value = options.fetch('file_size', 0)
        file_size = file_size_value.to_i

        output = {
          url: ::Addressable::URI.parse(url),
          headers: headers,
          file_size: file_size
        }

        output[:file_size] = get_file_size(output) if output[:file_size] < 1
        output
      end

      # Retrieve the file from the file system
      # @param options [Hash]
      def retrieve_file(options)
        file_uri = options.fetch(:url)
        file_size = options.fetch(:file_size)

        retrieved = 0
        File.open(file_uri.path, 'rb') do |f|
          until f.eof?
            chunk = f.read(chunk_size)
            retrieved += chunk.length
            yield(chunk, retrieved, file_size)
          end
        end
      end

      # Retrieve a resource over the HTTP
      # @param options [Hash]
      def retrieve_http(options)
        file_size = options.fetch(:file_size)
        headers = options.fetch(:headers)
        url = options.fetch(:url)
        retrieved = 0

        request = Typhoeus::Request.new(url.to_s, method: :get, headers: headers)
        request.on_headers do |response|
          raise DownloadError.new("#{self.class}: Failed to download #{url}: Status Code: #{response.code}", response) unless response.code == 200
        end
        request.on_body do |chunk|
          retrieved += chunk.bytesize
          yield(chunk, retrieved, file_size)
        end
        request.run
      end

      # Retrieve the file size
      # @param options [Hash]
      # @return [Integer] the size of the requested file
      def get_file_size(options)
        url = options.fetch(:url)
        headers = options.fetch(:headers)
        file_size = options.fetch(:file_size)

        case url.scheme
        when 'file'
          File.size(url.path)
        when /https?/
          response = Typhoeus.head(url.to_s, headers: headers)
          length_value = response.headers['Content-Length'] || file_size
          length_value.to_i
        else
          raise URI::BadURIError, "Unknown URI scheme: #{url.scheme}"
        end
      end
  end
end
