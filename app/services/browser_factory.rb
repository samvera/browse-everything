
class BrowserFactory
  def self.build(session:, url_options:)
    browser = BrowseEverything::Browser.new(url_options)
    browser.providers.values.each do |provider_handler|
      # The authentication token must be set here
      provider_handler.token = BrowseEverythingSession::ProviderSession.for(session: session, name: provider_handler.key.to_sym).token
    end
    browser
  end

  def self.for(name:)
    browser.providers[name]
  end
end
