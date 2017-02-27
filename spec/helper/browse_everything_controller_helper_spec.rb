require File.expand_path('../../spec_helper', __FILE__)

include BrowserConfigHelper

describe BrowseEverythingController, type: :controller do
  before(:all)  { stub_configuration   }
  after(:all)   { unstub_configuration }

  subject { helper_context.auth_link.scan(/state/) }

  let(:helper_context) { controller.view_context }
  let(:browser) { BrowseEverything::Browser.new(url_options) }

  before { allow(controller).to receive(:provider).and_return(provider) }

  context 'dropbox' do
    let(:provider) { browser.providers['dropbox'] }

    describe 'auth_link' do
      its(:length) { is_expected.to eq(1) }
    end
  end

  context 'box' do
    let(:provider) { browser.providers['box'] }

    describe 'auth_link' do
      its(:length) { is_expected.to eq(1) }
    end
  end
end
