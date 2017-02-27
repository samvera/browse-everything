describe BrowseEverything::FileEntry do
  let(:mtime) { Time.now }

  describe 'regular file' do
    subject do
      described_class.new(
        'file_id_01234', 'my_provider:/location/pa/th/file.m4v',
        'file.m4v', '1.2 GB', mtime, false
      )
    end

    it { is_expected.to be_a(described_class) }
    it { is_expected.not_to be_container }
    it { is_expected.not_to be_relative_parent_path }

    its(:id)       { is_expected.to eq('file_id_01234') }
    its(:location) { is_expected.to eq('my_provider:/location/pa/th/file.m4v') }
    its(:name)     { is_expected.to eq('file.m4v') }
    its(:size)     { is_expected.to eq('1.2 GB') }
    its(:mtime)    { is_expected.to eq(mtime) }
    its(:type)     { is_expected.to eq('video/mp4') }
  end

  describe 'directory' do
    subject do
      described_class.new(
        'directory_id_1234', 'my_provider:/location/pa/th',
        'th', '', mtime, true
      )
    end

    it { is_expected.to be_container }
    it { is_expected.not_to be_relative_parent_path }

    its(:type) { is_expected.to eq('application/x-directory') }
  end

  describe 'parent path' do
    subject do
      described_class.new(
        'directory_id_1234', 'my_provider:/location/pa/th',
        '..', '', mtime, true
      )
    end
    it { is_expected.to be_container }
    it { is_expected.to be_relative_parent_path }

    its(:type) { is_expected.to eq('application/x-directory') }
  end
end
