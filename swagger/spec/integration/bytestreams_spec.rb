# frozen_string_literal: true

require 'swagger_helper'
require 'pry-byebug'
require 'jwt'

# Please see https://github.com/rswag/rswag/issues/60#issuecomment-304457567
RSpec.describe 'Bytestream resources', type: :request do
  let(:provider_id) { 'file_system' }
  # This is a magic variable name, rswag needs it to stay authorization
  let(:authorization_object) do
    created = BrowseEverything::Authorization.build
    created.save
    created
  end
  let(:token) do
    payload = {
      data: authorization_object.serializable_hash
    }
    JWT.encode(payload, nil, 'none')
  end
  let(:authorization) { "Bearer #{token}" }
  let(:session) do
    created = BrowseEverything::Session.build(provider_id: provider_id, authorization_ids: [authorization_object.id])
    created.save
    created
  end
  let(:session_id) { session.id }

  path '/browse/sessions/{session_id}/bytestreams/{id}' do
    get 'it retrieves a file or asset from the provider' do
      security [apiKey: []]
      produces 'application/vnd.api+json'
      parameter name: :session_id, in: :path, type: :string
      parameter name: :id, in: :path, type: :string

      response '200', 'when the bytestream exists' do
        let(:file_path) { Rails.root.join('Gemfile').to_s }
        let(:id) { CGI.escape(file_path) }
        schema(
          type: :object,
          properties: {
            data: {
              type: :object,
              properties: {
                id: { type: :string },
                type: { type: :string },
                attributes: {
                  type: :object,
                  properties: {
                    id: { type: :string },
                    name: { type: :string },
                    mtime: { type: :string }
                  },
                  required: %w[name mtime media_type uri size location]
                },
                required: %w[id type attributes]
              }
            }
          },
          required: ['data']
        )

        run_test!
      end

      response '404', 'when the file cannot be found' do
        let(:id) { 'invalid' }
        run_test!
      end
    end
  end
end
