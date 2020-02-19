# frozen_string_literal: true

module BrowseEverything
  class Browser
    attr_reader :providers

    def initialize(opts = {})
      url_options = {}
      if opts.key?(:url_options)
        url_options = opts.delete(:url_options)
      else
        url_options = opts
        opts = BrowseEverything.config
      end

      @providers = ActiveSupport::HashWithIndifferentAccess.new
      opts.each_pair do |driver_key, config|
        driver = driver_key.to_s
        driver_klass = BrowseEverything::V1::Driver.const_get((config[:driver] || driver).camelize.to_sym)
        @providers[driver_key] = driver_klass.new(config.merge(url_options: url_options))
      rescue NameError
        Rails.logger.warn "Unknown provider: #{driver}"
      end
    end

    def first_provider
      @providers.to_hash.each_value.to_a.first
    end
  end
end
