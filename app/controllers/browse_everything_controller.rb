class BrowseEverythingController < ActionController::Base
  layout 'browse_everything'
  before_filter :load_browser

  def index
    render :layout => !request.xhr?
  end

  def show
    render :layout => !request.xhr?
  end
  
  def load_browser
    @browser = BrowseEverything::Browser.new(url_options)
    provider_name = params[:provider]
    @provider = @browser.providers[provider_name]
    @provider.token = session["#{provider_name}_token"] unless @provider.blank?
    @path = params[:path] || ''
  end

  def auth
    code = params[:code]
    provider_name = params[:state]
    @provider = @browser.providers[provider_name]
    session["#{provider_name}_token"] = @provider.connect(code)
  end
end