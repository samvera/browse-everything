
class BrowserFactory
  class << self
    def build(session:, url_options:)
      browser = BrowseEverything::Browser.new(url_options)
      browser.providers.values.each do |provider_handler|
        # The authentication token must be set here
        provider_handler.token = BrowseEverythingSession::ProviderSession.for(session: session, name: provider_handler.key.to_sym).token
      end
      browser
    end

    def for(name:, url_options: {})
      browser(url_options: url_options).providers[name]
    end
  end

  def self.browser(url_options: {})
    @browser ||= BrowseEverything::Browser.new(url_options)
  end
  private_class_method :browser
end
