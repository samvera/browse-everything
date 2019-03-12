# frozen_string_literal: true

include BrowserConfigHelper

describe BrowseEverything::Browser do
  let(:file_config) do
    "file_system:\n  home: '/file/config/home'\ndropbox:\n  client_id: 'DropboxId'\n  client_secret: 'DropboxClientSecret'\n  download_directory: 'tmp/'"
  end

  let(:global_config) do
    {
      file_system: {
        home: '/global/config/home'
      },
      dropbox: {
        client_id: 'DropboxId',
        client_secret: 'DropboxClientSecret',
        download_directory: 'tmp/'
      }
    }
  end

  let(:local_config) do
    {
      file_system: {
        home: '/local/config/home'
      },
      dropbox: {
        client_id: 'DropboxId',
        client_secret: 'DropboxClientSecret',
        download_directory: 'tmp/'
      },
      url_options: url_options
    }
  end

  describe 'file config' do
    let(:browser) { described_class.new(url_options) }

    before do
      BrowseEverything.config = nil
      allow(File).to receive(:read).and_return file_config
    end

    it 'has 2 providers' do
      expect(browser.providers.keys).to eq(%w[file_system dropbox])
      expect(browser.providers[:file_system]).to be_a BrowseEverything::Driver::FileSystem
      expect(browser.providers[:dropbox]).to be_a BrowseEverything::Driver::Dropbox
    end

    it 'uses the file configuration' do
      expect(browser.providers[:file_system].config[:home]).to eq('/file/config/home')
      expect(browser.providers['file_system'].config['home']).to eq('/file/config/home')
    end
  end

  describe 'global config' do
    let(:browser) { described_class.new(url_options) }

    before { BrowseEverything.configure(global_config) }

    it 'has 2 providers' do
      expect(browser.providers.keys).to eq(%w[file_system dropbox])
      expect(browser.providers[:file_system]).to be_a BrowseEverything::Driver::FileSystem
      expect(browser.providers[:dropbox]).to be_a BrowseEverything::Driver::Dropbox
    end

    it 'uses the global configuration' do
      expect(browser.providers[:file_system].config[:home]).to eq('/global/config/home')
      expect(browser.providers['file_system'].config['home']).to eq('/global/config/home')
    end
  end

  describe 'local config' do
    let(:browser) { described_class.new(local_config) }

    it 'has 2 providers' do
      expect(browser.providers.keys).to eq(%w[file_system dropbox])
      expect(browser.providers[:file_system]).to be_a BrowseEverything::Driver::FileSystem
      expect(browser.providers[:dropbox]).to be_a BrowseEverything::Driver::Dropbox
    end

    it 'uses the local configuration' do
      file_provider = browser.providers[:file_system]
      expect(file_provider.config[:home]).to eq('/local/config/home')
      expect(file_provider.config['home']).to eq('/local/config/home')
    end
  end

  context 'with an unknown provider' do
    let(:browser) do
      described_class.new(foo: { key: 'bar', secret: 'baz' }, url_options: url_options)
    end

    before do
      allow(Rails.logger).to receive(:warn)
    end

    it 'logs a warning' do
      browser
      expect(Rails.logger).to have_received(:warn).with('Unknown provider: foo')
    end
  end

  describe '#first_provider' do
    subject(:browser) { described_class.new(url_options) }

    it 'retrieves the first configured provider' do
      expect(browser.first_provider).to be_a BrowseEverything::Driver::FileSystem
    end
  end
end
