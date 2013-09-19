module BrowseEverything
  class Browser
    attr_reader :providers
    
    def initialize(url_options={},opts=nil)
      opts ||= YAML.load(File.read(File.join(Rails.root.to_s,'config','browse_everything_providers.yml')))
      @providers = {}
      opts.each_pair do |driver,config|
        begin
          driver_klass = BrowseEverything::Driver.const_get(driver.to_s.camelize.to_sym)
          @providers[driver] = driver_klass.new(config.merge(url_options: url_options))
        rescue
          logger.warn "Unknown provider: #{driver.to_s}"
        end
      end
    end

    def logger
      if defined?(Rails) && Rails.logger.present?
        Rails.logger
      else
        if @logger.nil?
          require 'logger'
          @logger = Logger.new($stderr)
        end
        @logger
      end
    end
  end
end