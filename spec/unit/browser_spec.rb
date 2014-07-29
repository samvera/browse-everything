require File.expand_path('../../spec_helper',__FILE__)

include BrowserConfigHelper

describe BrowseEverything::Browser do
  let(:file_config) { 
    {
      file_system: { home: '/file/config/home' },
      drop_box:    { app_key: 'FileConfigKey', app_secret: 'FileConfigSecret' }
    }.to_yaml
  }

  let(:global_config) {
    {
      file_system: { home: '/global/config/home' },
      drop_box:    { app_key: 'GlobalConfigKey', app_secret: 'GlobalConfigSecret' }
    }
  }

  let(:local_config) {
    {
      file_system: { home: '/local/config/home' },
      drop_box:    { app_key: 'LocalConfigKey', app_secret: 'LocalConfigSecret' },
      url_options: url_options
    }
  }

  describe "file config" do
    before(:each) { allow(File).to receive(:read).and_return(file_config) }
    subject { BrowseEverything::Browser.new(url_options) }

    it "should have 2 providers" do
      expect(subject.providers.keys).to eq([:file_system,:drop_box])
    end

    it "should use the file configuration" do
      expect(subject.providers[:drop_box].config[:app_key]).to eq('FileConfigKey')
    end
  end

  describe "global config" do
    before(:each) { BrowseEverything.configure(global_config) }
    subject { BrowseEverything::Browser.new(url_options) }
    
    it "should have 2 providers" do
      expect(subject.providers.keys).to eq([:file_system,:drop_box])
    end

    it "should use the global configuration" do
      expect(subject.providers[:drop_box].config[:app_key]).to eq('GlobalConfigKey')
    end
  end

  describe "local config" do
    subject { BrowseEverything::Browser.new(local_config) }
    
    it "should have 2 providers" do
      expect(subject.providers.keys).to eq([:file_system,:drop_box])
    end

    it "should use the local configuration" do
      expect(subject.providers[:drop_box].config[:app_key]).to eq('LocalConfigKey')
    end
  end

  describe "unknown provider" do
    subject { 
      BrowseEverything::Browser.new(local_config.merge(foo: { key: 'bar', secret: 'baz' }))
    }

    it "should complain but continue" do
      allow(Rails.logger).to receive(:warn).with('Unknown provider: foo')
      expect(subject.providers.keys).to eq([:file_system,:drop_box])
    end
  end
end
