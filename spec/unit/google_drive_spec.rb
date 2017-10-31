include BrowserConfigHelper

describe BrowseEverything::Driver::GoogleDrive, vcr: { cassette_name: 'google_drive', record: :none } do
  before(:all)  { stub_configuration   }
  after(:all)   { unstub_configuration }

  let(:browser) { BrowseEverything::Browser.new(url_options) }
  let(:provider) { browser.providers['google_drive'] }
  let(:provider_yml) do
    {
      client_id: 'CLIENTID', client_secret: 'CLIENTSECRET',
      url_options: { port: '3000', protocol: 'http://', host: 'example.com' }
    }
  end

  describe 'simple properties' do
    subject { provider }

    its(:name)      { is_expected.to eq('Google Drive') }
    its(:key)       { is_expected.to eq('google_drive') }
    its(:icon)      { is_expected.to eq('google-plus-sign') }
  end

  describe '#validate_config' do
    it 'raises and error with an incomplete configuration' do
      expect { BrowseEverything::Driver::GoogleDrive.new({}) }.to raise_error(BrowseEverything::InitializationError)
    end

    it 'raises and error with a configuration without a client secret' do
      expect { BrowseEverything::Driver::GoogleDrive.new(client_id: 'test-client-id') }.to raise_error(BrowseEverything::InitializationError)
    end
  end

  context 'with a valid configuration' do
    let(:driver) { described_class.new(provider_yml) }

    before do
      driver.connect({ code: 'code' }, {})
    end

    describe '#authorized?' do
      it 'is authorized' do
        expect(driver.authorized?).to be true
      end
    end

    describe '#contents' do
      subject(:files) { driver.contents.to_a }

      it 'retrieves files' do
        expect(files).not_to be_empty
        expect(files.first).to be_a BrowseEverything::FileEntry
        expect(files.first.location).to eq 'google_drive:asset-id2'
        expect(files.first.mtime).to be_a DateTime
        expect(files.first.name).to eq 'asset-name2.pdf'
        expect(files.first.size).to eq 891764
        expect(files.first.type).to eq 'application/pdf'
      end
    end

    describe '#link_for' do
      subject(:link) { driver.link_for('asset-id2') }

      it 'generates the link for a Google Drive asset' do
        expect(link).to be_an Array
        expect(link.first).to eq 'https://drive.google.com/uc?id=id&export=download'
        expect(link.last).to be_a Hash
        expect(link.last).to include auth_header: { 'Authorization' => 'Bearer access-token' }
        expect(link.last).to include :expires
        expect(link.last).to include file_name: 'asset-name2.pdf'
        expect(link.last).to include file_size: 0
      end
    end

    describe '#auth_link' do
      subject(:uri) { driver.auth_link }

      it 'exposes the authorization endpoint URI' do
        expect(uri).to be_a Addressable::URI
        expect(uri.to_s).to eq 'https://accounts.google.com/o/oauth2/auth?access_type=offline&client_id=CLIENTID&redirect_uri=http://example.com:3000/browse/connect&response_type=code&scope=https://www.googleapis.com/auth/drive'
      end
    end

    describe '#drive' do
      subject(:drive) { driver.drive }

      it 'exposes the Google Drive API client' do
        expect(drive).to be_a Google::Apis::DriveV3::DriveService
      end

      context 'with an expired token' do
        let(:auth_client) { instance_double(Signet::OAuth2::Client) }
        before do
          allow(auth_client).to receive(:fetch_access_token!).and_return('test-renewed-token')
          allow(auth_client).to receive(:expired?).and_return(true)
          allow(driver).to receive(:auth_client).and_return(auth_client)
        end

        it 'exposes the Google Drive API client with a renewed authorization token', invalid: true do
          expect(auth_client).to receive(:update_token!).with('test-renewed-token')
          expect(drive).to be_a Google::Apis::DriveV3::DriveService
        end
      end

      context 'with an empty token after expiry' do
        let(:auth_client) { instance_double(Signet::OAuth2::Client) }
        before do
          allow(auth_client).to receive(:fetch_access_token!).and_return(nil)
          allow(auth_client).to receive(:expired?).and_return(true)
          allow(driver).to receive(:auth_client).and_return(auth_client)
        end

        it 'exposes the Google Drive API client with a renewed authorization token', invalid: true do
          expect(drive).to be_a Google::Apis::DriveV3::DriveService
          expect(drive.authorization).to be nil
        end
      end
    end
  end
end
