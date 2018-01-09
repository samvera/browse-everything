include BrowserConfigHelper

describe BrowseEverything::Driver::FileSystem do
  before(:all)  { stub_configuration   }
  after(:all)   { unstub_configuration }
  let(:home)    { File.expand_path(BrowseEverything.config['file_system'][:home]) }
  let(:browser) { BrowseEverything::Browser.new(url_options) }
  let(:provider) { browser.providers['file_system'] }

  it '#validate_config' do
    expect { described_class.new({}) }.to raise_error(BrowseEverything::InitializationError)
  end

  describe 'simple properties' do
    subject    { provider                }
    its(:name) { is_expected.to eq('File System') }
    its(:key)  { is_expected.to eq('file_system') }
    its(:icon) { is_expected.to be_a(String)     }
    specify    { is_expected.to be_authorized    }
  end

  describe '#contents' do
    context 'root directory' do
      let(:contents) { provider.contents('/') }
      context '[0]' do
        subject { contents[0] }
        its(:name) { is_expected.to eq('dir_1') }
        specify    { is_expected.to be_container }
      end
      context '[1]' do
        subject { contents[1] }
        its(:name) { is_expected.to eq('dir_2') }
        specify    { is_expected.to be_container }
      end
      context '[2]' do
        subject { contents[2] }
        its(:name)     { is_expected.to eq('file 1.pdf')              }
        its(:size)     { is_expected.to eq(2256)                      }
        its(:location) { is_expected.to eq("file_system:#{File.join(home, 'file 1.pdf')}") }
        its(:type)     { is_expected.to eq('application/pdf') }
        specify        { is_expected.not_to be_container }
      end
      context '[3]' do
        subject { contents[3] }
        its(:name)     { is_expected.to eq('file_1.pdf')              }
        its(:size)     { is_expected.to eq(2256)                      }
        its(:location) { is_expected.to eq("file_system:#{File.join(home, 'file_1.pdf')}") }
        its(:type)     { is_expected.to eq('application/pdf') }
        specify        { is_expected.not_to be_container }
      end
    end

    context 'subdirectory' do
      let(:contents) { provider.contents('/dir_1') }
      context '[0]' do
        subject { contents[0] }
        its(:name) { is_expected.to eq('..') }
        specify    { is_expected.to be_container }
      end
      context '[1]' do
        subject { contents[1] }
        its(:name) { is_expected.to eq('dir_3') }
        specify    { is_expected.to be_container }
      end
      context '[2]' do
        subject { contents[2] }
        its(:name)     { is_expected.to eq('file_2.txt') }
        its(:location) { is_expected.to eq("file_system:#{File.join(home, 'dir_1/file_2.txt')}") }
        its(:type)     { is_expected.to eq('text/plain') }
        specify        { is_expected.not_to be_container }
      end
    end

    context 'single file' do
      let(:contents) { provider.contents('/dir_1/dir_3/file_3.m4v') }
      context '[0]' do
        subject { contents[0] }
        its(:name)     { is_expected.to eq('file_3.m4v') }
        its(:location) { is_expected.to eq("file_system:#{File.join(home, 'dir_1/dir_3/file_3.m4v')}") }
        its(:size)     { is_expected.to eq(3879)              }
        its(:type)     { is_expected.to eq('video/mp4')       }
        specify        { is_expected.not_to be_container }
      end
    end
  end

  describe "#link_for('/path/to/file')" do
    subject { provider.link_for('/path/to/file') }
    it { is_expected.to eq(['file:///path/to/file', { file_name: 'file', file_size: 0 }]) }
  end
end
