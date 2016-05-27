require File.expand_path('../../spec_helper',__FILE__)

include BrowserConfigHelper

describe BrowseEverythingController, type: :controller do
  before(:all)  { stub_configuration   }
  after(:all)   { unstub_configuration }

  let(:helper_context) {controller.view_context}
  let(:browser) { BrowseEverything::Browser.new(url_options) }
  let(:provider) { browser.providers['dropbox'] }

  before do
    allow(controller).to receive(:provider).and_return(provider)
  end
  describe "auth_link" do
    subject {helper_context.auth_link}
    it "has a single state" do
      expect(subject.scan(/state/).length).to eq 1
    end
  end
end
