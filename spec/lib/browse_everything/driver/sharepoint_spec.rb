# frozen_string_literal: true

include BrowserConfigHelper

describe BrowseEverything::Driver::Sharepoint do
  let(:browser) { BrowseEverything::Browser.new(url_options) }
  let(:provider) { browser.providers['sharepoint'] }
  let(:config) do
    {
      client_id: 'CLIENTID', client_secret: 'CLIENTSECRET',
      tenant_id: 'TENANTID', redirect_uri: 'http://example.com/browse/connect',
      scope: 'offline_access https://graph.microsoft.com/.default'
    }
  end
  let(:provider_yml) do
    {
      url_options: { port: '3000', protocol: 'http://', host: 'example.com' }
    }.merge!(config)
  end
  let(:oauth_response_body) do
    '{
     "access_token": "access-token",
     "token_type": "Bearer",
     "expires_in": 3600,
     "refresh_token": "refresh-token"
    }'
  end

  before do
    stub_configuration

    stub_request(
      :post, "https://login.microsoftonline.com/#{provider_yml[:tenant_id]}/oauth2/v2.0/token"
    ).to_return(
      body: oauth_response_body,
      status: 200,
      headers: {
        'Content-Type' => 'application/json; charset=UTF-8'
      }
    )
  end

  after do
    unstub_configuration
  end

  describe 'simple properties' do
    subject { provider }

    its(:name)      { is_expected.to eq('Sharepoint') }
    its(:key)       { is_expected.to eq('sharepoint') }
    its(:icon)      { is_expected.to eq('cloud') }
  end

  describe '#validate_config' do
    it 'does not raise an error with a complete configuration' do
      expect { described_class.new(config) }.to_not raise_error(BrowseEverything::InitializationError)
    end

    it 'raises an error with an incomplete configuration' do
      expect { described_class.new({}) }.to raise_error(BrowseEverything::InitializationError)
    end

    it 'raises an error with a configuration without a client secret' do
      expect { described_class.new(config.except(:client_secret)) }.to raise_error(BrowseEverything::InitializationError)
    end

    it 'raises an error with a configuration without a client id' do
      expect { described_class.new(config.except(:client_id)) }.to raise_error(BrowseEverything::InitializationError)
    end

    it 'raises an error with a configuration without a tenant id' do
      expect { described_class.new(config.except(:tenant_id)) }.to raise_error(BrowseEverything::InitializationError)
    end

    it 'raises an error with a configuration without a redirect uri' do
      expect { described_class.new(config.except(:redirect_uri)) }.to raise_error(BrowseEverything::InitializationError)
    end

    it 'raises an error with a configuration without a scope' do
      expect { described_class.new(config.except(:scope)) }.to raise_error(BrowseEverything::InitializationError)
    end
  end

  context 'with a valid connection' do
    let(:driver) { described_class.new(provider_yml) }

    before do
      driver.connect({ code: 'code' }, {}, nil)
      allow(driver).to receive(:root_site).and_return('site')
    end

    describe '#authorized?' do
      it 'is authorized' do
        expect(driver.authorized?).to be true
      end
    end

    describe '#contents' do
      let(:team) do
        {
          'value': [
            {
              'id': 'team-id1',
              'displayName': 'Team'
            }
          ]
        }.to_json
      end
      let(:drive) do
        {
          'value': [
            {
              'id': 'drive-id2',
              'name': 'Test OneDrive',
              'lastModifiedDateTime': Time.current
            }
          ]
        }.to_json
      end

      before do
        stub_request(
          :get, "https://graph.microsoft.com/v1.0/me/joinedTeams?$select=id,displayName"
        ).to_return(
          body: team,
          status: 200,
          headers: {}
        )

        stub_request(
          :get, "https://graph.microsoft.com/v1.0/me/drives?$select=id,name,lastModifiedDateTime"
        ).to_return(
          body: drive,
          status: 200,
          headers: {}
        )
      end

      context 'without id' do
        subject(:contents) { driver.contents.to_a }

        it 'retrieves all top level sites and drives' do
          expect(contents).not_to be_empty

          expect(contents.first).to be_a BrowseEverything::FileEntry
          expect(contents.first.location).to eq 'sharepoint:team-id1/drives'
          expect(contents.first.mtime).to eq nil
          expect(contents.first.name).to eq 'Team'
          expect(contents.first.size).to eq nil
          expect(contents.first.type).to eq 'application/x-directory'

          expect(contents.last).to be_a BrowseEverything::FileEntry
          expect(contents.last.location).to eq 'sharepoint:drive-id2/root/children'
          expect(contents.last.mtime).to be_a Date
          expect(contents.last.name).to eq 'Test OneDrive'
          expect(contents.last.size).to eq nil
          expect(contents.last.type).to eq 'application/x-directory'
        end
      end

      context 'with id' do
        subject(:contents) { driver.contents('drive-id2/root/children').to_a }
        let(:file) do
          {
            'value': [
              {
                'id': 'asset-id3',
                'name': 'asset-name3.pdf',
                'size': 5336,
                'lastModifiedDateTime': Time.current,
                'parentReference': {
                  'driveId': 'drive-id2',
                  'driveType': 'business',
                  'id': 'asset-id3'
                },
                'file': {
                  'mimeType': 'application/pdf'
                },
                '@microsoft.graph.downloadUrl': 'http://microsoft-download.com'
              }
            ]
          }.to_json
        end

        before do
          stub_request(
            :get, 'https://graph.microsoft.com/v1.0/me/drives/drive-id2/root/children'
          ).to_return(
            body: file,
            status: 200,
            headers: {}
          )
        end

        it 'retrieves files' do
          expect(contents.first).to be_a BrowseEverything::FileEntry
          expect(contents.first.location).to eq 'sharepoint:drive-id2/items/asset-id3'
          expect(contents.first.mtime).to be_a Date
          expect(contents.first.name).to eq 'asset-name3.pdf'
          expect(contents.first.size).to eq 5336
          expect(contents.first.type).to eq 'application/pdf'
        end

        it 'does not retrieve higher level items' do
          expect(contents.length).to eq 1
        end
      end
    end

    describe '#link_for' do
      subject(:link) { driver.link_for('drive-id2/items/asset-id3') }
      let(:file) do
        {
          'id': 'asset-id3',
          'name': 'asset-name3.pdf',
          'size': 5336,
          'lastModifiedDateTime': Time.current,
          'parentReference': {
            'driveId': 'drive-id2',
            'driveType': 'business',
            'id': 'asset-id3'
          },
          'file': {
            'mimeType': 'application/pdf'
          },
          '@microsoft.graph.downloadUrl': 'http://microsoft-download.com/asset-id3'
        }.to_json
      end

      before do
        stub_request(
          :get, 'https://graph.microsoft.com/v1.0/me/drives/drive-id2/items/asset-id3'
        ).to_return(
          body: file,
          status: 200,
          headers: {}
        )
      end

      it 'generates the link for a Sharepoint asset' do
        expect(link).to be_an Array
        expect(link.first).to eq 'http://microsoft-download.com/asset-id3'
        expect(link.last).to be_a Hash
        expect(link.last).to include file_name: 'asset-name3.pdf'
        expect(link.last).to include file_size: 5336
      end
    end

    describe '#auth_link' do
      subject(:uri) { driver.auth_link }

      it 'exposes the authorization endpoint URI' do
        expect(uri).to be_a Addressable::URI
        expect(uri.normalize.to_s).to eq 'https://login.microsoftonline.com/TENANTID/oauth2/v2.0/authorize?client_id=CLIENTID&scope=offline_access%20https://graph.microsoft.com/.default&redirect_uri=http://example.com/browse/connect&response_type=code'
      end

      context 'when permissions have changed' do
        before { driver.instance_variable_set(:@consent_refresh, 'true') }

        it 'includes "prompt=consent" in the auth_link' do
          expect(uri).to be_a Addressable::URI
          expect(uri.normalize.to_s).to eq 'https://login.microsoftonline.com/TENANTID/oauth2/v2.0/authorize?client_id=CLIENTID&scope=offline_access%20https://graph.microsoft.com/.default&redirect_uri=http://example.com/browse/connect&response_type=code&prompt=consent'
        end
      end
    end
  end
end
