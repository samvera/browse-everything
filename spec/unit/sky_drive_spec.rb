require File.expand_path('../../spec_helper',__FILE__)



describe BrowseEverything::Driver::SkyDrive do
  include BrowseEverything::Engine.routes.url_helpers

  def provider_yml
    {client_id: "CLIENTID", client_secret: "CLIENTSECRET", url_options:{ :port=>"3000", :protocol=>"http://", host:"example.com"}}
  end

  def redirect_url
    connector_response_url(provider_yml[:url_options])
  end

  it "can connect" do
    stub_request(:post, "https://login.live.com/oauth20_token.srf").
        with(:body => {"client_id"=>"CLIENTID", "client_secret"=>"CLIENTSECRET", "code"=>"code", "grant_type"=>"authorization_code", "redirect_uri"=>"#{redirect_url}"}).
        to_return(:status => 200,
                  :body => {
                      "token_type"            =>  "bearer",
                      "expires_at"            =>  (Time.now +  (60 * 60 * 24)).to_i,
                      "scope"                 =>  "wl.skydrive_update,wl.offline_access",
                      "access_token"          =>  "access_token",
                      "refresh_token"         =>  "refresh_token",
                      "authentication_token"  =>  "authentication_token"
                  }.to_json,
                  :headers  => {
                      "content-type"          =>  "application/json"})


    driver = BrowseEverything::Driver::SkyDrive.new(provider_yml)
    driver.connect({code:"code"},{})
    driver.authorized?.should == true
  end

  it "can connect but expires" do
    stub_request(:post, "https://login.live.com/oauth20_token.srf").
        with(:body => {"client_id"=>"CLIENTID", "client_secret"=>"CLIENTSECRET", "code"=>"code", "grant_type"=>"authorization_code", "redirect_uri"=>"#{redirect_url}"}).
        to_return(:status => 200,
                  :body => {
                      "token_type"            =>  "bearer",
                      "expires_at"            =>  (Time.now -  (60 * 60 * 24)).to_i,
                      "scope"                 =>  "wl.skydrive_update,wl.offline_access",
                      "access_token"          =>  "access_token",
                      "refresh_token"         =>  "refresh_token",
                      "authentication_token"  =>  "authentication_token"
                  }.to_json,
                  :headers  => {
                      "content-type"          =>  "application/json"})


    driver = BrowseEverything::Driver::SkyDrive.new(provider_yml)
    driver.connect({code:"code"},{})
    driver.authorized?.should == false
  end

end