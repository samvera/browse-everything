require File.expand_path('../../spec_helper',__FILE__)

describe BrowseEverythingHelper do

  let(:test_class) {
    Class.new do
      include BrowseEverythingHelper
      attr_reader :params
      def initialize params
        @params = params
      end
    end
  }

  let(:test_file) { BrowseEverything::FileEntry.new 0, '/path/to/file.mp4', 'file.mp4', 12345, Time.now, false }
  
  it "should match a full type" do
    expect(test_class.new(accept: 'video/mp4').is_acceptable?(test_file)).to eq(true)
  end
  
  it "should match a wildcard type" do
    expect(test_class.new(accept: 'video/*').is_acceptable?(test_file)).to eq(true)
  end
  
  it "should not match the wrong full type" do
    expect(test_class.new(accept: 'video/mpeg').is_acceptable?(test_file)).to eq(false)
  end

  it "should not match the wrong wildcard type" do
    expect(test_class.new(accept: 'audio/*').is_acceptable?(test_file)).to eq(false)
  end

  it "should match a type list" do
    expect(test_class.new(accept: 'audio/*, video/mp4').is_acceptable?(test_file)).to eq(true)
  end

  it "should not match the wrong type list" do
    expect(test_class.new(accept: 'audio/*, application/json').is_acceptable?(test_file)).to eq(false)
  end
end
