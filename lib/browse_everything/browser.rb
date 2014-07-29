module BrowseEverything
  class Browser
    attr_reader :providers
    
    def initialize(opts = {})
      url_options = {}
      if opts.has_key?(:url_options)
        url_options = opts.delete(:url_options)
      else
        url_options = opts
        opts = BrowseEverything.config
      end

      @providers = {}
      opts.each_pair do |driver,config|
        begin
          driver_klass = BrowseEverything::Driver.const_get((config[:driver] || driver.to_s).camelize.to_sym)
          @providers[driver] = driver_klass.new(config.merge(url_options: url_options))
        rescue
          Rails.logger.warn "Unknown provider: #{driver.to_s}"
        end
      end
    end
  end
end
