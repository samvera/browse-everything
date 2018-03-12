# frozen_string_literal: true

include BrowserConfigHelper

describe BrowserFactory do
  subject(:browser_factory) { described_class.new }

  let(:session) { instance_double(BrowseEverythingSession::ProviderSession) }
  let(:provider_session_class) { class_double(BrowseEverythingSession::ProviderSession).as_stubbed_const(transfer_nested_constants: true) }
  let(:provider_session) { instance_double(BrowseEverythingSession::ProviderSession) }
  let(:provider) { instance_double(BrowseEverything::Driver::Base) }
  let(:browser_class) { class_double(BrowseEverything::Browser).as_stubbed_const(transfer_nested_constants: true) }
  let(:browser) { instance_double(BrowseEverything::Browser) }

  before do
    allow(provider).to receive(:key).and_return('test-provider')
    allow(provider).to receive(:token=)
    allow(browser).to receive(:providers).and_return('test-provider' => provider)
    allow(browser_class).to receive(:new).and_return(browser)
    allow(provider_session).to receive(:token).and_return('test-token')
    allow(provider_session_class).to receive(:for).and_return(provider_session)
  end

  describe '.for' do
    it 'retrieves a driver by name' do
      expect(described_class.for(name: 'test-provider')).to eq provider
    end
  end

  describe '.build' do
    before do
      described_class.build(session: session, url_options: url_options)
    end

    it 'initializes a Browser Object and provides it with a sessionized access token' do
      expect(browser_class).to have_received(:new).with(url_options)
      expect(provider_session_class).to have_received(:for).with(session: session, name: 'test-provider'.to_sym)
    end
  end
end
