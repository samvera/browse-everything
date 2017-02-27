describe BrowseEverything::Driver::SkyDrive do
  include BrowseEverything::Engine.routes.url_helpers

  let(:provider_yml) do
    {
      client_id: 'CLIENTID', client_secret: 'CLIENTSECRET',
      url_options: { port: '3000', protocol: 'http://', host: 'example.com' }
    }
  end

  let(:redirect_url) { connector_response_url(provider_yml[:url_options]) }

  let(:response_body) do
    {
      'client_id' => 'CLIENTID', 'client_secret' => 'CLIENTSECRET', 'code' => 'code',
      'grant_type' => 'authorization_code', 'redirect_uri' => redirect_url.to_s
    }
  end

  let(:driver) { described_class.new(provider_yml) }

  subject { driver }

  context 'when expiration is in the future' do
    before do
      stub_request(:post, 'https://login.live.com/oauth20_token.srf')
          .with(body: response_body)
          .to_return(status: 200,
                     body: {
                       'token_type'            =>  'bearer',
                       'expires_at'            =>  (Time.now + (60 * 60 * 24)).to_i,
                       'scope'                 =>  'wl.skydrive_update,wl.offline_access',
                       'access_token'          =>  'access_token',
                       'refresh_token'         =>  'refresh_token',
                       'authentication_token'  =>  'authentication_token'
                     }.to_json,
                     headers: {
                       'content-type'          =>  'application/json' })
      driver.connect({ code: 'code' }, {})
    end

    it { is_expected.to be_authorized }
  end

  context 'when the session has expired' do
    before do
      stub_request(:post, 'https://login.live.com/oauth20_token.srf')
          .with(body: response_body)
          .to_return(status: 200,
                     body: {
                       'token_type'            =>  'bearer',
                       'expires_at'            =>  (Time.now - (60 * 60 * 24)).to_i,
                       'scope'                 =>  'wl.skydrive_update,wl.offline_access',
                       'access_token'          =>  'access_token',
                       'refresh_token'         =>  'refresh_token',
                       'authentication_token'  =>  'authentication_token'
                     }.to_json,
                     headers: {
                       'content-type'          =>  'application/json' })
      driver.connect({ code: 'code' }, {})
    end

    it { is_expected.not_to be_authorized }
  end
end
