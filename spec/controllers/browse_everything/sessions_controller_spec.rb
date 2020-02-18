# frozen_string_literal: true

require 'jwt'
require 'spec_helper'

RSpec.describe BrowseEverything::SessionsController, type: :controller do
  routes { BrowseEverything::Engine.routes }

  let(:authorization) do
    authorization = BrowseEverything::Authorization.build(code: 'invalid')
    authorization.save
    authorization
  end

  let(:token) do
    payload = {
      data: authorization.serializable_hash
    }

    JWT.encode(payload, nil, 'none')
  end

  after do
    authorization.destroy
  end

  describe '#create' do
    let(:params) do
      {
        provider_id: 'google_drive',
        token: token
      }
    end

    before do
      post :create, params: params, format: :json
    end

    it 'constructs and persists a Session' do
      session = assigns(:session)
      expect(session).to be_a BrowseEverything::Session
      expect(session.provider_id).to eq 'google_drive'
      expect(session.host).to eq 'test.host'
      expect(session.port).to eq 80

      session.destroy
    end
  end

  describe '#update' do
  end
end
