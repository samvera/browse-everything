require File.expand_path('../../spec_helper',__FILE__)

include BrowserConfigHelper

describe BrowseEverything::Driver::FileSystem do
  before(:all)  { stub_configuration   }
  after(:all)   { unstub_configuration }
  let(:home)    { File.expand_path(BrowseEverything.config['file_system'][:home]) }
  let(:browser) { BrowseEverything::Browser.new(url_options) }
  let(:provider) { browser.providers['file_system'] }

  it "#validate_config" do
    expect { BrowseEverything::Driver::FileSystem.new({}) }.to raise_error(BrowseEverything::InitializationError)
  end

  describe "simple properties" do
    subject    { provider                }
    its(:name) { should == 'File System' }
    its(:key)  { should == 'file_system' }
    its(:icon) { should be_a(String)     }
    specify    { should be_authorized    }
  end

  describe "#contents" do
    context "root directory" do
      let(:contents) { provider.contents('/') }
      context "[0]" do
        subject { contents[0] }
        its(:name) { should == 'dir_1'   }
        specify    { should be_container }
      end
      context "[1]" do
        subject { contents[1] }
        its(:name) { should == 'dir_2'   }
        specify    { should be_container }
      end
      context "[2]" do
        subject { contents[2] }
        its(:name)     { should == 'file_1.pdf'              }
        its(:size)     { should == 2256                      }
        its(:location) { should == "file_system:#{File.join(home,'file_1.pdf')}" }
        its(:type)     { should == "application/pdf"         }
        specify        { should_not be_container             }
      end
    end

    context "subdirectory" do
      let(:contents) { provider.contents('/dir_1') }
      context "[0]" do
        subject { contents[0] }
        its(:name) { should == '..'      }
        specify    { should be_container }
      end
      context "[1]" do
        subject { contents[1] }
        its(:name) { should == 'dir_3'   }
        specify    { should be_container }
      end
      context "[2]" do
        subject { contents[2] }
        its(:name)     { should == 'file_2.txt'      }
        its(:location) { should == "file_system:#{File.join(home,'dir_1/file_2.txt')}" }
        its(:type)     { should == "text/plain"      }
        specify        { should_not be_container     }
      end
    end

    context "single file" do
      let(:contents) { provider.contents('/dir_1/dir_3/file_3.m4v') }
      context "[0]" do
        subject { contents[0] }
        its(:name)     { should == 'file_3.m4v'      }
        its(:location) { should == "file_system:#{File.join(home,'dir_1/dir_3/file_3.m4v')}" }
        its(:size)     { should == 3879              }
        its(:type)     { should == "video/mp4"       }
        specify        { should_not be_container     }
      end
    end
  end

  describe "#link_for('/path/to/file')" do
    subject { provider.link_for('/path/to/file') }
    it { should == ["file:///path/to/file", {:file_name=>"file", :file_size=>0}] }
  end
end
