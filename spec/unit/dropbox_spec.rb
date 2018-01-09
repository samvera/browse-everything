include BrowserConfigHelper

describe BrowseEverything::Driver::Dropbox, vcr: { cassette_name: 'dropbox', record: :none } do
  before(:all)  { stub_configuration   }
  after(:all)   { unstub_configuration }

  let(:browser) { BrowseEverything::Browser.new(url_options) }
  let(:provider) { browser.providers['dropbox'] }
  let(:provider_yml) do
    {
      client_id: 'client-id',
      client_secret: 'client-secret'
    }
  end

  describe '#validate_config' do
    it 'raises and error with an incomplete configuration' do
      expect { BrowseEverything::Driver::Dropbox.new({}) }.to raise_error(BrowseEverything::InitializationError)
    end

    it 'raises and error with a configuration without a client secret' do
      expect { BrowseEverything::Driver::Dropbox.new(client_id: 'test-client-id') }.to raise_error(BrowseEverything::InitializationError)
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
    before { driver.connect({ code: 'code' }, {}) }

    describe '#auth_link' do
      subject { driver.auth_link }
      it { is_expected.to start_with('https://www.dropbox.com/oauth2/authorize') }
    end

    describe '#authorized?' do
      subject { driver }
      it { is_expected.to be_authorized }
    end

    describe '#contents' do
      context 'within the root folder' do
        let(:contents) { driver.contents }

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

    describe '#details' do
      subject(:file_metadata) { driver.details('/Getting Started.pdf') }

      it 'retrieves the metadata for a file' do
        expect(file_metadata).to be_a BrowseEverything::FileEntry
        expect(file_metadata.id).to eq '/Getting Started.pdf'
        expect(file_metadata.location).to eq 'dropbox:/Getting Started.pdf'
        expect(file_metadata.name).to eq 'Getting Started.pdf'
        expect(file_metadata.size).to eq 249159
        expect(file_metadata.mtime).to be_a Time
        expect(file_metadata.container?).to eq false
      end
    end

    describe '#link_for' do
      subject(:link_args) { driver.link_for('/Getting Started.pdf') }

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
end
