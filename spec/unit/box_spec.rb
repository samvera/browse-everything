include BrowserConfigHelper

describe BrowseEverything::Driver::Box, vcr: { cassette_name: 'box', record: :none } do
  before(:all)  { stub_configuration   }
  after(:all)   { unstub_configuration }

  let(:browser) { BrowseEverything::Browser.new(url_options) }
  let(:provider) { browser.providers['box'] }
  let(:auth_params) do
    {
      'code' => 'CODE',
      'state' => 'box'
    }
  end

  # To re-record the VCR responses, you will need to substitute the 'token' and 'refresh_token' values with the
  # actual tokens returned from Box.
  #
  # The easiest way to do this is output @token to the Rails log from the box_client method:
  #
  #   def box_client
  #     Rails.logger.info(@token)
  #     [...]
  #
  # Make sure you have the internal_test_app built and have copied your client id and secret to the yaml config file.
  # With the test app running, you can authenticate to your Box account to browse files, and should see the
  # tokens listed in the Rails log. Once you have copied the new tokens, the spec test will run and use your tokens
  # to authenticate to Box. To record the new responses replace `record: :none` with `record: :all`.
  let(:token) do
    {
      'token' => 'TOKEN',
      'refresh_token' => 'REFRESH_TOKEN'
    }
  end

  subject    { provider }

  its(:name) { is_expected.to eq('Box') }
  its(:key)  { is_expected.to eq('box') }
  its(:icon) { is_expected.to be_a(String) }

  describe '#validate_config' do
    it 'raises and error with an incomplete configuration' do
      expect { BrowseEverything::Driver::Box.new({}) }.to raise_error(BrowseEverything::InitializationError)
    end
  end

  describe '#auth_link' do
    subject { provider.auth_link }

    it { is_expected.to start_with('https://www.box.com/api/oauth2/authorize') }
    it { is_expected.to include('browse%2Fconnect') }
    it { is_expected.to include('response_type') }
  end

  describe '#authorized?' do
    subject { provider.authorized? }
    context 'when the access token is not registered' do
      it { is_expected.to be(false) }
    end
    context 'when the access tokens are registered and not expired' do
      before { provider.token = token.merge('expires_at' => Time.now.to_i + 360) }
      it { is_expected.to be(true) }
    end
    context 'when the access tokens are registered but no expiration time' do
      before { provider.token = token }
      it { is_expected.to be(false) }
    end
    context 'when the access tokens are registered but expired' do
      before { provider.token = token.merge('expires_at' => Time.now.to_i - 360) }
      it { is_expected.to be(false) }
    end
  end

  describe '#connect' do
    it 'registers new tokens' do
      expect(provider).to receive(:register_access_token).with(kind_of(OAuth2::AccessToken))
      provider.connect(auth_params, 'data')
    end
  end

  describe '#contents' do
    before { provider.token = token }

    context 'with files and folders in the root directory' do
      let(:root_directory) { provider.contents('') }
      let(:long_file)      { root_directory[0] }
      let(:sas_directory)  { root_directory[6] }
      let(:tar_file)       { root_directory[10] }

      describe 'the first item' do
        subject { long_file }
        its(:name)     { is_expected.to start_with('A very looooooooooooong box folder') }
        its(:location) { is_expected.to eq('box:20375782799') }
        it             { is_expected.to be_container }
      end

      describe 'the SaS - Development Team directory' do
        subject { sas_directory }
        its(:name)     { is_expected.to eq('SaS - Development Team') }
        its(:location) { is_expected.to eq('box:2459961273') }
        its(:id)       { is_expected.to eq('2459961273') }
        it             { is_expected.to be_container }
      end

      describe 'a file' do
        subject { tar_file }
        its(:name)     { is_expected.to eq('failed.tar.gz') }
        its(:size)     { is_expected.to eq(28_650_839) }
        its(:location) { is_expected.to eq('box:25581309763') }
        its(:type)     { is_expected.to eq('application/x-gzip') }
        its(:id)       { is_expected.to eq('25581309763') }
        it             { is_expected.not_to be_container }
      end
    end

    context 'with files and folders in the SaS - Development Team directory' do
      let(:sas_directory)    { provider.contents('2459961273') }
      let(:parent_directory) { sas_directory[0] }
      let(:apps_dir)         { sas_directory[1] }
      let(:equipment)        { sas_directory[12] }

      describe 'the first item' do
        subject { parent_directory }

        its(:name)     { is_expected.to eq('..') }
        its(:location) { is_expected.to be_empty }
        its(:id)       { is_expected.to be_kind_of(Pathname) }
        it             { is_expected.to be_container }
      end
      describe 'the second item' do
        subject { apps_dir }

        its(:name)     { is_expected.to eq('Apps&Int') }
        its(:id)       { is_expected.to eq('2459974427') }
        it             { is_expected.to be_container }
      end
      describe 'a file' do
        subject { equipment }

        its(:name)     { is_expected.to eq('Equipment.boxnote') }
        its(:size)     { is_expected.to eq(10140) }
        its(:location) { is_expected.to eq('box:76960974625') }
        its(:type)     { is_expected.to eq('application/octet-stream') }
        its(:id)       { is_expected.to eq('76960974625') }
        it             { is_expected.not_to be_container }
      end
    end
  end

  describe '#link_for' do
    before { provider.token = token }

    context 'with a file from the root directory' do
      let(:link) { provider.link_for('25581309763') }

      specify { expect(link[0]).to start_with('https://dl.boxcloud.com/d/1') }
      specify { expect(link[1]).to have_key(:expires) }
    end

    context 'with a file from the SaS - Development Team directory' do
      let(:link) { provider.link_for('76960974625') }

      specify { expect(link[0]).to start_with('https://dl.boxcloud.com/d/1') }
      specify { expect(link[1]).to have_key(:expires) }
    end
  end
end
