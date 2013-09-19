require File.expand_path('../../spec_helper',__FILE__)

describe BrowseEverything::FileEntry do
  subject { 
    BrowseEverything::FileEntry.new('scheme://location/pa/th/file.m4v','file.m4v', '1.2 GB', Time.now, 'video/mp4')
  }

  it "type" do
    expect(subject).to be_a BrowseEverything::FileEntry
  end
end