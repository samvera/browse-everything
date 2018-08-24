# frozen_string_literal: true

include BrowserConfigHelper

describe BrowseEverything::Driver::Dropbox do
  let(:browser) { BrowseEverything::Browser.new(url_options) }
  let(:provider) { browser.providers['dropbox'] }
  let(:provider_yml) do
    {
      client_id: 'client-id',
      client_secret: 'client-secret'
    }
  end
  let(:oauth_response_body) do
    '{"access_token": "test-access-token", "token_type": "bearer", "uid": "test-user-id", "account_id": "dbid:id"}'
  end

  before do
    stub_configuration

    stub_request(
      :post, 'https://api.dropboxapi.com/oauth2/token'
    ).to_return(
      body: oauth_response_body,
      status: 200,
      headers: {
        'Content-Type' => 'text/javascript'
      }
    )
  end

  after do
    unstub_configuration
  end

  describe '#validate_config' do
    it 'raises and error with an incomplete configuration' do
      expect { described_class.new({}) }.to raise_error(BrowseEverything::InitializationError)
    end

    it 'raises and error with a configuration without a client secret' do
      expect { described_class.new(client_id: 'test-client-id') }.to raise_error(BrowseEverything::InitializationError)
    end
  end

  describe 'simple properties' do
    subject    { provider }

    its(:name) { is_expected.to eq('Dropbox') }
    its(:key)  { is_expected.to eq('dropbox') }
    its(:icon) { is_expected.to be_a(String) }
  end

  context 'with a valid configuration' do
    let(:driver) { described_class.new(provider_yml) }
    let(:connector_response_url_options) do
      {
        protocol: 'http://',
        host: 'test.host',
        port: 80
      }
    end

    before { driver.connect({ code: 'code' }, {}, connector_response_url_options) }

    describe '#auth_link' do
      subject { driver.auth_link(connector_response_url_options) }

      it { is_expected.to start_with('https://www.dropbox.com/oauth2/authorize') }
    end

    describe '#authorized?' do
      subject { driver }

      it { is_expected.to be_authorized }
    end

    describe '#contents' do
      context 'when in the root folder' do
        let(:contents) { driver.contents }
        let(:list_folder_response) do
          '{"entries": [{".tag": "folder", "name": "Photos", "path_lower": "/photos", "path_display": "/Photos", "id": "id:XAAAAAAAAAALA"}, {".tag": "file", "name": "Getting Started.pdf", "path_lower": "/getting started.pdf", "path_display": "/Getting Started.pdf", "id": "id:XAAAAAAAAAAKg", "client_modified": "2012-11-10T18:33:28Z", "server_modified": "2012-11-10T18:33:27Z", "rev": "60b9427f2", "size": 249159, "content_hash": "c3dfdd86981548e48bc8efb6c4162c76ba961ec92e60f6ba26189068a41fcaf2"}], "cursor": "AAFu-_dOPQTQnqOIb9JklCPYSxWtNRrBBOU4nNkY78wTCc-ktCP4MtIoN1nmOESizkoue2dpu3FbMwDM6BQbgkLObH_Ge-H0BYaPwjfLk5cUHZHd1swkMYGLWELfX_PIHH9hCmU0C8sUL2EJ-7y6BcRFpdOvPmxiu6azVyCx_Il7kA", "has_more": false}'
        end

        before do
          stub_request(
            :post, 'https://api.dropboxapi.com/2/files/list_folder'
          ).with(
            body: '{"recursive":false,"include_media_info":false,"include_deleted":false,"path":""}'
          ).to_return(
            body: list_folder_response,
            status: 200,
            headers: {
              'Content-Type' => 'application/json'
            }
          )
        end

        it 'retrieves all folders the root folders' do
          expect(contents).not_to be_empty
          folder_metadata = contents.first
          expect(folder_metadata).to be_a BrowseEverything::FileEntry
          expect(folder_metadata.id).to eq '/Photos'
          expect(folder_metadata.location).to eq 'dropbox:/Photos'
          expect(folder_metadata.name).to eq 'Photos'
          expect(folder_metadata.size).to eq nil
          expect(folder_metadata.mtime).to eq nil
          expect(folder_metadata.container?).to eq true
        end
      end
    end

    describe '#link_for' do
      subject(:link_args) { driver.link_for('/Getting Started.pdf') }
      before do
        stub_request(
          :post, 'https://content.dropboxapi.com/2/files/download'
        ).to_return(
          body: '{"name": "Getting Started.pdf", "path_lower": "/getting started.pdf", "path_display": "/Getting Started.pdf", "id": "id:XAAAAAAAAAAKg", "client_modified": "2012-11-10T18:33:28Z", "server_modified": "2012-11-10T18:33:27Z", "rev": "60b9427f2", "size": 249159, "content_hash": "c3dfdd86981548e48bc8efb6c4162c76ba961ec92e60f6ba26189068a41fcaf2"}',
          status: 200,
          headers: {
            'Content-Type' => 'application/json'
          }
        )
      end

      it 'provides link arguments for accessing the file' do
        expect(link_args.first).to be_a String
        expect(link_args.first).to start_with 'file:/'
        expect(link_args.first).to include 'Getting Started.pdf'

        File.open(link_args.first.gsub('file:', '')) do |downloaded_file|
          expect(downloaded_file.read).not_to be_empty
        end
      end
    end
  end

  describe '#handle_deprecated_config' do
    let(:provider_yml) do
      {
        app_key: 'client-id',
        client_secret: 'client-secret'
      }
    end
    let(:driver) { described_class.new(provider_yml) }

    it 'maps the deprecated config value pair to the new one' do
      driver.handle_deprecated_config(:app_key, :client_id)
      expect(driver.config).to include :app_key
      expect(driver.config).to include :client_id
      expect(driver.config[:app_key]).to eq('client-id')
    end
  end
end
