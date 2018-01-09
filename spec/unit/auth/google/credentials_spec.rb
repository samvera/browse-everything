describe BrowseEverything::Auth::Google::Credentials do
  subject(:credentials) { described_class.new }
  describe '#fetch_access_token' do
    before do
      credentials.access_token = 'test-token'
    end
    it 'generates a Hash if an access token has already been set' do
      expect(credentials.fetch_access_token).to be_a Hash
      expect(credentials.fetch_access_token).to include('access_token' => 'test-token')
    end
  end
end
