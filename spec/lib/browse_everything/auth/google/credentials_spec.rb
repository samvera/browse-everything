# frozen_string_literal: true

describe BrowseEverything::Auth::Google::Credentials do
  subject(:credentials) { described_class.new }

  describe '#fetch_access_token' do
    let(:response) { double }

    before do
      WebMock.disable!

      allow(response).to receive(:status_code).and_return('200')
      allow(response).to receive(:body).and_return('{}')
      allow(response).to receive(:header).and_return(content_type: 'application/json')

      connection = instance_double(Faraday::Connection)
      allow(connection).to receive(:post).and_return(response)
      faraday = class_double('Faraday').as_stubbed_const(transfer_nested_constants: true)
      allow(faraday).to receive(:default_connection).and_return(connection)
    end

    context 'when an access has already been retrieved' do
      before do
        credentials.access_token = 'test-token'
      end

      it 'generates a Hash if an access token has already been set' do
        expect(credentials.fetch_access_token).to be_a Hash
        expect(credentials.fetch_access_token).to include('access_token' => 'test-token')
      end
    end

    it 'requests a new token from the OAuth provider' do
      expect(credentials.fetch_access_token).to be_a Hash
      expect(credentials.fetch_access_token).to eq({ "granted_scopes" => nil })
    end

    after do
      WebMock.enable!
    end
  end
end
