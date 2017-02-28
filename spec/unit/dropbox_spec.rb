include BrowserConfigHelper

describe BrowseEverything::Driver::Dropbox, vcr: { cassette_name: 'dropbox', record: :none } do
  before(:all)  { stub_configuration   }
  after(:all)   { unstub_configuration }

  let(:browser) { BrowseEverything::Browser.new(url_options) }
  let(:provider) { browser.providers['dropbox'] }
  let(:auth_params) do {
    'code' => 'FakeDropboxAuthorizationCodeABCDEFG',
    'state' => 'GjDcUhPNZrZzdsw%2FghBy2A%3D%3D|dropbox'
  }
  end
  let(:csrf_data) { { 'token' => 'GjDcUhPNZrZzdsw%2FghBy2A%3D%3D' } }

  it '#validate_config' do
    expect { BrowseEverything::Driver::Dropbox.new({}) }.to raise_error(BrowseEverything::InitializationError)
  end

  describe 'simple properties' do
    subject    { provider }
    its(:name) { is_expected.to eq('Dropbox') }
    its(:key)  { is_expected.to eq('dropbox') }
    its(:icon) { is_expected.to be_a(String) }
  end

  describe '#auth_link' do
    subject { provider.auth_link[0] }

    it { is_expected.to start_with('https://www.dropbox.com/1/oauth2/authorize') }
    it { is_expected.to include('browse%2Fconnect') }
    it { is_expected.to include('state') }
  end

  describe 'authorization' do
    subject { provider }
    before { provider.connect(auth_params, csrf_data) }
    it { is_expected.to be_authorized }
  end

  describe '#contents' do
    before { provider.connect(auth_params, csrf_data) }

    context 'root directory' do
      let(:contents) { provider.contents('') }

      context '[0]' do
        subject { contents[0] }
        its(:name) { is_expected.to eq('Apps')   }
        specify    { is_expected.to be_container }
      end
      context '[1]' do
        subject { contents[1] }
        its(:name) { is_expected.to eq('Books')  }
        specify    { is_expected.to be_container }
      end
      context '[4]' do
        subject { contents[4] }
        its(:name)     { is_expected.to eq('iPad intro.pdf') }
        its(:size)     { is_expected.to eq(208218) }
        its(:location) { is_expected.to eq('dropbox:/iPad intro.pdf') }
        its(:type)     { is_expected.to eq('application/pdf') }
        specify        { is_expected.not_to be_container }
      end
    end

    context 'subdirectory' do
      let(:contents) { provider.contents('/Writer') }
      context '[0]' do
        subject { contents[0] }

        its(:name) { is_expected.to eq('..')     }
        specify    { is_expected.to be_container }
      end
      context '[1]' do
        subject { contents[1] }

        its(:name)     { is_expected.to eq('About Writer.txt') }
        its(:location) { is_expected.to eq('dropbox:/Writer/About Writer.txt') }
        its(:type)     { is_expected.to eq('text/plain') }
        specify        { is_expected.not_to be_container }
      end
      context '[2]' do
        subject { contents[2] }

        its(:name)     { is_expected.to eq('Markdown Test.txt') }
        its(:location) { is_expected.to eq('dropbox:/Writer/Markdown Test.txt') }
        its(:type)     { is_expected.to eq('text/plain') }
        specify        { is_expected.not_to be_container }
      end
      context '[3]' do
        subject { contents[3] }

        its(:name)     { is_expected.to eq('Writer FAQ.txt') }
        its(:location) { is_expected.to eq('dropbox:/Writer/Writer FAQ.txt') }
        its(:type)     { is_expected.to eq('text/plain') }
        specify        { is_expected.not_to be_container }
      end
    end

    context '#details' do
      subject { provider.details('') }
      its(:name) { is_expected.to eq('Apps') }
    end
  end

  describe '#link_for' do
    before { provider.connect(auth_params, csrf_data) }

    context '[0]' do
      let(:link) { provider.link_for('/Writer/Writer FAQ.txt') }

      specify { expect(link[0]).to eq('https://dl.dropboxusercontent.com/1/view/FakeDropboxAccessPath/Writer/Writer%20FAQ.txt') }
      specify { expect(link[1]).to have_key(:expires) }
    end

    context '[1]' do
      let(:link) { provider.link_for('/Writer/Markdown Test.txt') }

      specify { expect(link[0]).to eq('https://dl.dropboxusercontent.com/1/view/FakeDropboxAccessPath/Writer/Markdown%20Test.txt') }
      specify { expect(link[1]).to have_key(:expires) }
    end
  end
end
