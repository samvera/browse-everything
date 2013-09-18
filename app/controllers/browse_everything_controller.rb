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
    @browser = BrowseEverything::Browser.new
    @provider = @browser.providers[params[:provider]]
    @path = params[:path] || ''
  end  
end