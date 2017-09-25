require 'httparty'
require 'tempfile'
require 'addressable'

module BrowseEverything
  class Retriever
    attr_accessor :chunk_size

    def initialize
      @chunk_size = 16384
    end

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

    def retrieve(spec, &block)
      if spec.key?('expires') && Time.parse(spec['expires']) < Time.now
        raise ArgumentError, "Download spec expired at #{spec['expires']}"
      end

      parsed_spec = parse_spec(spec)

      case parsed_spec[:url].scheme
      when 'file'
        retrieve_file(parsed_spec, &block)
      when /https?/
        retrieve_http(parsed_spec, &block)
      else
        raise URI::BadURIError, "Unknown URI scheme: #{parsed_spec[:url].scheme}"
      end
    end

    private

      def parse_spec(spec)
        result = {
          url: ::Addressable::URI.parse(spec['url']),
          headers: spec['auth_header'] || {},
          file_size: spec.fetch('file_size', 0).to_i
        }

        result[:headers].each_pair { |k, v| result[:headers][k] = v.tr('+', ' ') }
        result[:file_size] = get_file_size(result) if result[:file_size] < 1
        result
      end

      def retrieve_file(parsed_spec)
        retrieved = 0
        File.open(parsed_spec[:url].path, 'rb') do |f|
          until f.eof?
            chunk = f.read(chunk_size)
            retrieved += chunk.length
            yield(chunk, retrieved, parsed_spec[:file_size])
          end
        end
      end

      def retrieve_http(parsed_spec)
        retrieved = 0
        stream_body = parsed_spec[:file_size] > 500.megabytes

        HTTParty.get(parsed_spec[:url].to_s, stream_body: stream_body, headers: parsed_spec[:headers]) do |chunk|
          retrieved += chunk.length
          yield(chunk, retrieved, parsed_spec[:file_size])
        end
      end

      def get_file_size(parsed_spec)
        case parsed_spec[:url].scheme
        when 'file'
          File.size(url.path)
        when /https?/
          response = HTTParty.head(parsed_spec[:url].to_s, headers: parsed_spec[:headers])
          response.content_length
        else
          raise URI::BadURIError, "Unknown URI scheme: #{url.scheme}"
        end
      end
  end
end
