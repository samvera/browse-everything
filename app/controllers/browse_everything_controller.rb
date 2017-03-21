require File.expand_path('../../helpers/browse_everything_helper', __FILE__)

class BrowseEverythingController < ActionController::Base
  layout 'browse_everything'
  helper BrowseEverythingHelper

  protect_from_forgery with: :exception

  after_action { session["#{provider_name}_token"] = provider.token unless provider.nil? }

  def index
    render layout: !request.xhr?
  end

  def show
    render layout: !request.xhr?
  end

  def auth
    session["#{provider_name}_token"] = provider.connect(params, session["#{provider_name}_data"])
  end

  def resolve
    selected_files = params[:selected_files] || []
    @links = selected_files.collect do |file|
      p, f = file.split(/:/)
      (url, extra) = browser.providers[p].link_for(f)
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

    def auth_link
      @auth_link ||= if provider.present?
                       link, data = provider.auth_link
                       session["#{provider_name}_data"] = data
                       link = "#{link}&state=#{provider.key}" unless link.to_s.include?('state')
                       link
                     end # else nil, implicitly
    end

    def browser
      if @browser.nil?
        @browser = BrowseEverything::Browser.new(url_options)
        @browser.providers.values.each do |p|
          p.token = session["#{p.key}_token"]
        end
      end
      @browser
    end

    def browse_path
      @path ||= params[:path] || ''
    end

    def provider
      @provider ||= browser.providers[provider_name]
    end

    def provider_name
      @provider_name ||= params[:provider] || params[:state].to_s.split(/\|/).last
    end

    helper_method :auth_link
    helper_method :browser
    helper_method :browse_path
    helper_method :provider
    helper_method :provider_name
end
