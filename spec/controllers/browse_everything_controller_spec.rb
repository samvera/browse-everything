# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BrowseEverythingController, type: :controller do
  routes { Rails.application.class.routes }

  let(:driver) { instance_double(BrowseEverything::Driver::Base) }

  before do
    allow(driver).to receive(:authorized?).and_return(true)
    allow(controller).to receive(:provider).and_return(driver)
  end

  describe '#auth' do
    let(:provider_session) { instance_double(BrowseEverythingSession::ProviderSession) }

    before do
      allow(controller).to receive(:params).and_return('code' => 'test-code')
      allow(provider_session).to receive(:data).and_return(nil)
      allow(driver).to receive(:connect)
      controller.auth
    end
    it 'retrieves the authorization code from the parameters' do
      expect(driver).to have_received(:connect).with({ 'code' => 'test-code' }, nil)
    end
  end

  describe '#show' do
    let(:file1) { instance_double(BrowseEverything::FileEntry) }
    let(:file2) { instance_double(BrowseEverything::FileEntry) }

    before do
      allow(driver).to receive(:contents).and_return([file1, file2])
      allow(controller).to receive(:render).with(partial: 'files', layout: true)
    end

    it 'renders the files retrieved by the driver' do
      controller.show
      expect(controller).to have_received(:render).with(partial: 'files', layout: true)
    end

    context 'when an error occurs while retrieving the files' do
      before do
        allow(controller).to receive(:render).with(partial: 'files', layout: true).and_raise(StandardError)
        allow(controller).to receive(:render).with(partial: 'auth', layout: true)
      end

      it 'directs the user to reauthenticate after attempting to render the files' do
        controller.show
        expect(controller).to have_received(:render).with(partial: 'auth', layout: true)
      end
    end
  end
end
