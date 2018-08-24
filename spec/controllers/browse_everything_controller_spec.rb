# frozen_string_literal: true

require 'spec_helper'
require 'signet/errors'

RSpec.describe BrowseEverythingController, type: :controller do
  routes { Rails.application.class.routes }

  let(:provider) { instance_double(BrowseEverything::Driver::Base) }

  before do
    allow(provider).to receive(:authorized?).and_return(true)
    allow(controller).to receive(:provider).and_return(provider)
  end

  describe '#auth' do
    let(:provider_session) { instance_double(BrowseEverythingSession::ProviderSession) }
    let(:connector_response_url_options) do
      {
        protocol: 'http://',
        host: 'test.host',
        port: 80
      }
    end

    before do
      allow(controller).to receive(:params).and_return('code' => 'test-code')
      allow(provider_session).to receive(:data).and_return(nil)
      allow(provider).to receive(:connect)
      controller.auth
    end

    it 'retrieves the authorization code from the parameters' do
      expect(provider).to have_received(:connect).with({ 'code' => 'test-code' }, nil, connector_response_url_options)
    end
  end

  describe '#show' do
    let(:file1) { instance_double(BrowseEverything::FileEntry) }
    let(:file2) { instance_double(BrowseEverything::FileEntry) }

    before do
      allow(provider).to receive(:contents).and_return([file1, file2])
      allow(controller).to receive(:render).with(partial: 'files', layout: true)
    end

    it 'renders the files retrieved by the provider' do
      allow(provider).to receive(:contents).and_return([file1, file2])
      controller.show
      expect(controller).to have_received(:render).with(partial: 'files', layout: true)
    end

    context 'when an authentication error occurs while retrieving the files' do
      let(:provider_session) { instance_double(BrowseEverythingSession::ProviderSession) }

      before do
        controller.instance_variable_set(:@provider_session, provider_session)
        allow(controller).to receive(:render).with(partial: 'auth', layout: true)
        allow(controller).to receive(:render).with(partial: 'files', layout: true).and_raise(Signet::AuthorizationError)
        allow(provider_session).to receive(:token=)
        allow(provider_session).to receive(:code=)
        allow(provider_session).to receive(:data=)
        controller.show
      end

      it 'clears the Rails session of auth. data' do
        expect(provider_session).to have_received(:token=).with(nil)
        expect(provider_session).to have_received(:code=).with(nil)
        expect(provider_session).to have_received(:data=).with(nil)
        expect(provider_session.instance_variable_get(:@provider_session)).to be_nil
      end
    end

    context 'when a remote API error occurs while retrieving the files' do
      before do
        allow(controller).to receive(:render).with(partial: 'auth', layout: true)
        allow(controller).to receive(:render).with(partial: 'files', layout: true).and_raise(StandardError)
        allow(controller).to receive(:reset_provider_session!)
        controller.show
      end

      it 'directs the user to reauthenticate after attempting to render the files' do
        expect(controller).to have_received(:render).with(partial: 'auth', layout: true)
        expect(controller).to have_received(:reset_provider_session!)
      end
    end
  end

  describe '#validate_provider_authorized' do
    it 'raises an exception if the provider is not authorized' do
      expect { controller.validate_provider_authorized }.not_to raise_error

      allow(provider).to receive(:authorized?).and_return(false)
      expect { controller.validate_provider_authorized }.to raise_error(BrowseEverything::NotAuthorizedError)
    end
  end

  describe '#provider_contents_next_page' do
    before do
      allow(provider).to receive(:contents_next_page).and_return(1)
    end

    it 'calculates the next page number' do
      expect(controller.provider_contents_next_page).to eq(1)

      allow(provider).to receive(:contents_next_page).and_return(2)
      expect(controller.provider_contents_next_page).to eq(2)
    end
  end

  describe '#provider_contents_last_page?' do
    before do
      allow(provider).to receive(:contents_last_page?).and_return(false)
    end

    it 'determines whether or not the client is requesting the last page of results' do
      expect(controller.provider_contents_last_page?).to be false

      allow(provider).to receive(:contents_last_page?).and_return(true)
      expect(controller.provider_contents_last_page?).to be true
    end
  end

  describe '#resolve' do
    routes { BrowseEverything::Engine.routes }
    let(:selected_files) { ['file_system:/my/test/file.txt'] }

    before do
      allow(provider).to receive(:token).and_return(nil)
    end

    it 'renders the download links' do
      get :resolve, format: :json, params: { selected_files: selected_files }
      expect(response.body).not_to be_empty
      json_response = JSON.parse(response.body)
      expect(json_response).not_to be_empty
      resolved = json_response.first
      expect(resolved).to include 'url' => 'file:///my/test/file.txt'
      expect(resolved).to include 'file_name' => 'file.txt'
      expect(resolved).to include 'file_size' => 0
    end
  end
end
