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

    before do
      allow(controller).to receive(:params).and_return('code' => 'test-code')
      allow(provider_session).to receive(:data).and_return(nil)
      allow(provider).to receive(:connect)
      controller.auth
    end
    it 'retrieves the authorization code from the parameters' do
      expect(provider).to have_received(:connect).with({ 'code' => 'test-code' }, nil)
    end
  end

  describe '#show' do
    let(:file1) { instance_double(BrowseEverything::FileEntry) }
    let(:file2) { instance_double(BrowseEverything::FileEntry) }

    before do
      allow(driver).to receive(:contents).and_return([file1, file2])
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
        allow(provider).to receive(:contents).and_raise(Signet::AuthorizationError)
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
        allow(provider).to receive(:contents).and_raise(StandardError)
        allow(controller).to receive(:reset_provider_session!)
        controller.show
      end

      it 'directs the user to reauthenticate after attempting to render the files' do
        controller.show
        expect(controller).to have_received(:render).with(partial: 'auth', layout: true)
        expect(controller).to have_received(:reset_provider_session!)
      end
    end
  end
end
