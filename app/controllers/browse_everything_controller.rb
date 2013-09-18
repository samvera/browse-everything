class BrowseEverythingController < ActionController::Base
  layout 'browse_everything'
  before_filter :load_browser

  def index
    render :layout => !request.xhr?
  end

  def show
    if @provider.present? and not @provider.authorized?
      link, data = @provider.auth_link
      @auth_link = "#{link}&state=#{@provider_name}"
      session["#{@provider_name}_data"] = data
    end
    render :layout => !request.xhr?
  end
  
  def load_browser
    @browser = BrowseEverything::Browser.new(url_options)
    @provider_name = params[:provider] || params[:state].to_s.split(/\|/).last
    @provider = @browser.providers[@provider_name]
    @provider.token = session["#{@provider_name}_token"] unless @provider.blank?
    @path = params[:path] || ''
  end

  def auth
    code = params[:code]
    @provider = @browser.providers[@provider_name]
    session["#{@provider_name}_token"] = @provider.connect(params,session["#{@provider_name}_data"])
  end
end