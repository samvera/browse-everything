include BrowserConfigHelper

describe BrowseEverything::Browser do
  let(:file_config) do
    {
      file_system: { home: '/file/config/home' },
      dropbox:    { app_key: 'FileConfigKey', app_secret: 'FileConfigSecret' }
    }.to_yaml
  end

  let(:global_config) do
    {
      file_system: { home: '/global/config/home' },
      dropbox:    { app_key: 'GlobalConfigKey', app_secret: 'GlobalConfigSecret' }
    }
  end

  let(:local_config) do
    {
      file_system: { home: '/local/config/home' },
      dropbox:    { app_key: 'LocalConfigKey', app_secret: 'LocalConfigSecret' },
      url_options: url_options
    }
  end

  describe 'file config' do
    let(:browser) { described_class.new(url_options) }

    before { allow(File).to receive(:read).and_return(file_config) }

    it 'has 2 providers' do
      expect(browser.providers.keys).to eq([:file_system, :dropbox])
    end

    it 'uses the file configuration' do
      expect(browser.providers[:dropbox].config[:app_key]).to eq('FileConfigKey')
    end
  end

  describe 'global config' do
    let(:browser) { described_class.new(url_options) }

    before { BrowseEverything.configure(global_config) }

    it 'has 2 providers' do
      expect(browser.providers.keys).to eq([:file_system, :dropbox])
    end

    it 'uses the global configuration' do
      expect(browser.providers[:dropbox].config[:app_key]).to eq('GlobalConfigKey')
    end
  end

  describe 'local config' do
    let(:browser) { described_class.new(local_config) }

    it 'has 2 providers' do
      expect(browser.providers.keys).to eq([:file_system, :dropbox])
    end

    it 'uses the local configuration' do
      expect(browser.providers[:dropbox].config[:app_key]).to eq('LocalConfigKey')
    end
  end

  describe 'unknown provider' do
    let(:browser) do
      described_class.new(local_config.merge(foo: { key: 'bar', secret: 'baz' }))
    end

    it 'complains but continue' do
      expect(Rails.logger).to receive(:warn).with('Unknown provider: foo')
      expect(browser.providers.keys).to eq([:file_system, :dropbox])
    end
  end
end
