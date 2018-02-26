require File.expand_path('../../helpers/browse_everything_helper', __FILE__)

class BrowseEverythingController < ActionController::Base
  layout 'browse_everything'
  helper BrowseEverythingHelper

  protect_from_forgery with: :exception

  after_action do
    provider_session.token = provider.token unless provider.nil? || provider.token.blank?
  end

  def index
    render layout: !request.xhr?
  end

  # Either render the link to authorization or render the files
  # provider#show method is invoked here
  def show
    raise BrowseEverythingHelper::NotImplementedError, 'No provider supported' if provider.nil?
    raise BrowseEverythingHelper::NotAuthorizedError, 'Not authorized' unless provider.authorized?

    @provider_contents = provider.contents(browse_path)
    render partial: 'files', layout: !request.xhr?
  rescue StandardError => error
    reset_provider_session!

    # Should an error be raised, log the error and redirect the use to reauthenticate
    logger.warn "Failed to retrieve the hosted files: #{error}"
    render partial: 'auth', layout: !request.xhr?
  end

  # Action for the OAuth2 callback
  # Authenticate against the Google API and store the token in the session
  def auth
    # params contains the access code with with the key :code
    provider_session.token = provider.connect(params, provider_session.data)
  end

  def resolve
    selected_files = params[:selected_files] || []
    @links = selected_files.collect do |file|
      provider_key, uri = file.split(/:/)
      (url, extra) = browser.providers[provider_key].link_for(uri)
      result = { url: url }
      result.merge!(extra) unless extra.nil?
      result
    end
    respond_to do |format|
      format.html { render layout: false }
      format.json { render json: @links }
    end
  end

  private

    # Constructs or accesses an existing session manager Object
    # @return [BrowseEverythingSession::ProviderSession] the session manager
    def provider_session
      @provider_session ||= BrowseEverythingSession::ProviderSession.new(session: session, name: provider_name)
    end

    # Clears all authentication tokens, codes, and other data from the Rails session
    def reset_provider_session!
      return unless @provider_session
      @provider_session.token = nil
      @provider_session.code = nil
      @provider_session.data = nil
      @provider_session = nil
    end

    # Generates the authentication link for a given provider service
    # @return [String] the authentication link
    def auth_link
      @auth_link ||= if provider.present?
                       link, data = provider.auth_link
                       provider_session.data = data
                       link = "#{link}&state=#{provider.key}" unless link.to_s.include?('state')
                       link
                     end # else nil, implicitly
    end

    # Accesses the relative path for browsing from the Rails session
    # @return [String]
    def browse_path
      @path ||= params[:path] || ''
    end

    # Generate the provider name from the Rails session state value
    # @return [String]
    def provider_name_from_state
      params[:state].to_s.split(/\|/).last
    end

    # Generates the name of the provider using Rails session values
    # @return [String]
    def provider_name
      @provider_name ||= params[:provider] || provider_name_from_state
    end

    # Retrieve the Driver for each request
    # @return [BrowseEverything::Driver::Base]
    def provider
      browser.providers[provider_name]
    end

    # Constructs a browser manager Object
    # Browser state cannot persist between requests to the Controller
    # Hence, a Browser must be reinstantiated for each request using the state provided in the Rails session
    # @return [BrowseEverything::Browser]
    def browser
      BrowserFactory.build(session: session, url_options: url_options)
    end

    helper_method :auth_link
    helper_method :browser
    helper_method :browse_path
    helper_method :provider
    helper_method :provider_name
end
