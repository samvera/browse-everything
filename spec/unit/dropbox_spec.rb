require File.expand_path('../../spec_helper',__FILE__)

include BrowserConfigHelper

describe BrowseEverything::Driver::Dropbox, vcr: { cassette_name: 'dropbox', record: :none } do
  before(:all)  { stub_configuration   }
  after(:all)   { unstub_configuration }

  let(:browser) { BrowseEverything::Browser.new(url_options) }
  let(:provider) { browser.providers['dropbox'] }
  let(:auth_params) { {
    'code' => 'FakeDropboxAuthorizationCodeABCDEFG',
    'state' => 'GjDcUhPNZrZzdsw%2FghBy2A%3D%3D|dropbox'
  } }
  let(:csrf_data) { {'token' => 'GjDcUhPNZrZzdsw%2FghBy2A%3D%3D'} }

  it "#validate_config" do
    expect { BrowseEverything::Driver::Dropbox.new({}) }.to raise_error(BrowseEverything::InitializationError)
  end

  describe "simple properties" do
    subject    { provider                 }
    its(:name) { should == 'Dropbox'     }
    its(:key)  { should == 'dropbox'     }
    its(:icon) { should be_a(String)      }
  end

  context "authorization" do
    subject { provider }

    specify { should_not be_authorized }

    context "#auth_link" do
      specify { subject.auth_link[0].should start_with('https://www.dropbox.com/1/oauth2/authorize') }
      specify { subject.auth_link[0].should include('browse%2Fconnect') }
      specify { subject.auth_link[0].should include('state') }
    end

    it "should authorize" do
      subject.connect(auth_params,csrf_data)
      expect(subject).to be_authorized
    end
  end

  describe "#contents" do
    before(:each) { provider.connect(auth_params,csrf_data) }

    context "root directory" do
      let(:contents) { provider.contents('') }
      context "[0]" do
        subject { contents[0] }
        its(:name) { should == 'Apps'    }
        specify    { should be_container }
      end
      context "[1]" do
        subject { contents[1] }
        its(:name) { should == 'Books'   }
        specify    { should be_container }
      end
      context "[4]" do
        subject { contents[4] }
        its(:name)     { should == 'iPad intro.pdf'           }
        its(:size)     { should == 208218                 }
        its(:location) { should == "dropbox:/iPad intro.pdf" }
        its(:type)     { should == "application/pdf"          }
        specify        { should_not be_container              }
      end
    end

    context "subdirectory" do
      let(:contents) { provider.contents('/Writer') }
      context "[0]" do
        subject { contents[0] }
        its(:name) { should == '..'      }
        specify    { should be_container }
      end
      context "[1]" do
        subject { contents[1] }
        its(:name)     { should == 'About Writer.txt'      }
        its(:location) { should == "dropbox:/Writer/About Writer.txt" }
        its(:type)     { should == "text/plain"      }
        specify        { should_not be_container     }
      end
      context "[2]" do
        subject { contents[2] }
        its(:name)     { should == 'Markdown Test.txt'      }
        its(:location) { should == "dropbox:/Writer/Markdown Test.txt" }
        its(:type)     { should == "text/plain"      }
        specify        { should_not be_container     }
      end
      context "[3]" do
        subject { contents[3] }
        its(:name)     { should == 'Writer FAQ.txt'      }
        its(:location) { should == "dropbox:/Writer/Writer FAQ.txt" }
        its(:type)     { should == "text/plain"      }
        specify        { should_not be_container     }
      end
    end

    context "#details" do
      subject { provider.details('') }
      its(:name) { should == 'Apps'    }
    end
  end

  describe "#link_for" do
    before(:each) { provider.connect(auth_params,csrf_data) }

    context "[0]" do
      subject { provider.link_for('/Writer/Writer FAQ.txt') }
      specify { subject[0].should == "https://dl.dropboxusercontent.com/1/view/FakeDropboxAccessPath/Writer/Writer%20FAQ.txt" }
      specify { subject[1].should have_key(:expires) }
    end

    context "[1]" do
      subject { provider.link_for('/Writer/Markdown Test.txt') }
      specify { subject[0].should == "https://dl.dropboxusercontent.com/1/view/FakeDropboxAccessPath/Writer/Markdown%20Test.txt" }
      specify { subject[1].should have_key(:expires) }
    end
  end
end
