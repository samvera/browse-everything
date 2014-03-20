require File.expand_path('../../spec_helper',__FILE__)

include BrowserConfigHelper

describe BrowseEverything::Driver::Base do
  subject { BrowseEverything::Driver::Base.new({}) }

  describe "simple properties" do
    its(:name)      { should == 'Base'         }
    its(:key)       { should == 'base'         }
    its(:icon)      { should be_a(String)      }
    its(:auth_link) { should be_empty          }
    specify         { should_not be_authorized }
  end
  context "#connect" do
    specify { subject.connect({},{}).should be_blank }
  end
  context "#contents" do
    specify { subject.contents('').should be_empty }
  end
  context "#details" do
    specify { subject.details('/path/to/foo.txt').should be_nil }
  end
  context "#link_for" do
    specify { subject.link_for('/path/to/foo.txt').should == ['/path/to/foo.txt', { file_name: 'foo.txt' }] }
  end
end

