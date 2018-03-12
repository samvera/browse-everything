# frozen_string_literal: true

require File.expand_path('../spec_helper', __dir__)

include BrowserConfigHelper

describe BrowseEverythingController, type: :controller do
  subject { helper_context.auth_link.scan(/state/) }

  let(:helper_context) { controller.view_context }
  let(:browser) { BrowseEverything::Browser.new(url_options) }

  before do
    stub_configuration
    allow(controller).to receive(:provider).and_return(provider)
  end

  after do
    unstub_configuration
  end

  context 'when using Dropbox as a provider' do
    let(:provider) { browser.providers['dropbox'] }

    describe 'auth_link' do
      its(:length) { is_expected.to eq(1) }
    end
  end

  context 'when using Box as a provider' do
    let(:provider) { browser.providers['box'] }

    describe 'auth_link' do
      its(:length) { is_expected.to eq(1) }
    end
  end

  context 'when using Google Drive as a provider' do
    let(:provider) { browser.providers['google_drive'] }

    describe 'auth_link' do
      its(:length) { is_expected.to eq(1) }
    end
  end
end
