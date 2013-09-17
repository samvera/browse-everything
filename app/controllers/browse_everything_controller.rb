class BrowseEverythingController
  before_filter :load_browser

  def index
  end

  def show
  end
  
  def load_browser
    @browser = BrowseEverything::Browser.new(file_system: { home: Rails.root })
    @provider = @browser.providers[params[:provider]]
  end  
end