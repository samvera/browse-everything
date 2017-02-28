describe BrowseEverythingHelper do
  let(:test_class) do
    Class.new do
      include BrowseEverythingHelper
      attr_reader :params
      def initialize(params)
        @params = params
      end
    end
  end

  let(:test_file) { BrowseEverything::FileEntry.new 0, '/path/to/file.mp4', 'file.mp4', 12345, Time.now, false }

  it 'matches a full type' do
    expect(test_class.new(accept: 'video/mp4').is_acceptable?(test_file)).to eq(true)
  end

  it 'matches a wildcard type' do
    expect(test_class.new(accept: 'video/*').is_acceptable?(test_file)).to eq(true)
  end

  it 'does not match the wrong full type' do
    expect(test_class.new(accept: 'video/mpeg').is_acceptable?(test_file)).to eq(false)
  end

  it 'does not match the wrong wildcard type' do
    expect(test_class.new(accept: 'audio/*').is_acceptable?(test_file)).to eq(false)
  end

  it 'matches a type list' do
    expect(test_class.new(accept: 'audio/*, video/mp4').is_acceptable?(test_file)).to eq(true)
  end

  it 'does not match the wrong type list' do
    expect(test_class.new(accept: 'audio/*, application/json').is_acceptable?(test_file)).to eq(false)
  end
end
