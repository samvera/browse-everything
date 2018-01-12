describe BrowseEverythingSession::ProviderSession do
  subject(:provider_session) { described_class.new(session: session, name: name) }
  let(:session) { instance_double(ActionDispatch::Request::Session) }
  let(:name) { 'test_session' }

  describe '.for' do
    it 'provides a new session object' do
      expect(described_class.for(session: session, name: name)).to be_a described_class
    end
  end

  describe '.token' do
    before do
      allow(session).to receive(:[]=)
      allow(session).to receive(:[]).and_return('test-token')
      provider_session.token = 'test-token'
    end
    it 'sets and accesses the access token' do
      expect(provider_session.token).to eq 'test-token'
      expect(session).to have_received(:[]).with('test_session_token')
    end
  end

  describe '.code' do
    before do
      allow(session).to receive(:[]=)
      allow(session).to receive(:[]).and_return('test-code')
      provider_session.code = 'test-code'
    end
    it 'sets and accesses the access code' do
      expect(provider_session.code).to eq 'test-code'
      expect(session).to have_received(:[]).with('test_session_code')
    end
  end

  describe '.data' do
    before do
      allow(session).to receive(:[]=)
      allow(session).to receive(:[]).and_return('test' => 'data')
      provider_session.data = { 'test' => 'data' }
    end
    it 'sets and accesses the access data' do
      expect(provider_session.data).to eq('test' => 'data')
      expect(session).to have_received(:[]).with('test_session_data')
    end
  end
end
