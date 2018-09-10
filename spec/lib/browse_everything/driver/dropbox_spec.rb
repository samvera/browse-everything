# frozen_string_literal: true

include BrowserConfigHelper

describe BrowseEverything::Driver::Dropbox, vcr: { cassette_name: 'dropbox', record: :none } do
  let(:browser) { BrowseEverything::Browser.new(url_options) }
  let(:provider) { browser.providers['dropbox'] }
  let(:provider_yml) do
    {
      client_id: 'client-id',
      client_secret: 'client-secret'
    }
  end

  before do
    stub_configuration
  end

  after do
    unstub_configuration
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
