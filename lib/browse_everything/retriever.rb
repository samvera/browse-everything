require 'httparty'
require 'tempfile'

module BrowseEverything
  class Retriever
    attr_accessor :chunk_size
    
    def initialize
      @chunk_size = 16384
    end
    
    def download(spec, target=nil)
      if target.nil?
        ext = File.extname(spec['file_name'])
        base = File.basename(spec['file_name'],ext)
        target = Dir::Tmpname.create([base,ext]) {}
      end
      
      File.open(target, 'wb') do |output|
        self.retrieve(spec) do |chunk, retrieved, total| 
          output.write(chunk) 
          yield(target, retrieved, total) if block_given?
        end
      end
      return target
    end
    
    def retrieve(spec, &block)
      if spec.has_key?('expires') and Time.parse(spec['expires']) < Time.now
        raise ArugumentError, "Download spec expired at #{spec['expires']}"
      end
      
      url = URI.parse(spec['url'])
      retrieved = 0
      case url.scheme
      when 'file'
        File.open(url.path,'rb') do |f|
          while not f.eof?
            chunk = f.read(chunk_size)
            retrieved += chunk.length
            yield(chunk, retrieved, spec['file_size'].to_i)
          end
        end
      when /https?/
        headers = spec['auth_header'] || {}
        headers.each_pair do |k,v|
          headers[k] = v.gsub(/\+/,' ')
        end
        
        HTTParty.get(url.to_s, headers: headers) do |chunk| 
          retrieved += chunk.length
          yield(chunk, retrieved, spec['file_size'].to_i)
        end
      else
        raise URI::BadURIError, "Unknown URI scheme: #{uri.scheme}"
      end
    end

  end
end
