module BrowseEverything
  class Browser
    attr_reader :providers
    
    def initialize(opts={})
      @providers = {}
      opts.each_pair do |driver,config|
        driver_klass = BrowseEverything::Driver.const_get(driver.to_s.camelize.to_sym)
        @providers[driver] = driver_klass.new(config)
      end
    end
  end
end