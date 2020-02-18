# frozen_string_literal: true

require 'swagger_helper'
require 'pry-byebug'
require 'jwt'

# Please see https://github.com/rswag/rswag/issues/60#issuecomment-304457567
RSpec.describe 'Container resources', type: :request do
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

  path '/browse/sessions/{session_id}/containers' do
    get 'it retrieves the root directory or folder from the provider' do
      security [apiKey: []]

      produces 'application/vnd.api+json'
      parameter name: :session_id, in: :path, type: :string

      response '200', 'container exists' do
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
                  required: %w[id name mtime]
                },
                relationships: {
                  bytestreams: {
                    data: [
                      { id: { type: :string } },
                      { type: { type: :string } },
                      { attributes: { type: :object } }
                    ]
                  },
                  containers: {
                    data: [
                      { id: { type: :string } },
                      { type: { type: :string } },
                      { attributes: { type: :object } },
                      { relationships: { type: :object } }
                    ]
                  }
                }
              }
            }
          },
          required: ['data']
        )
        run_test!
      end
    end
  end

  path '/browse/sessions/{session_id}/containers/{id}' do
    get 'it retrieves a directory or folder from the provider' do
      security [apiKey: []]
      produces 'application/vnd.api+json'
      parameter name: :session_id, in: :path, type: :string
      parameter name: :id, in: :path, type: :string

      response '200', 'when the container exists' do
        let(:file_path) { Rails.root.to_s }
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
                  required: %w[id name mtime]
                },
                relationships: {
                  bytestreams: {
                    data: [
                      { id: { type: :string } },
                      { type: { type: :string } },
                      { attributes: { type: :object } }
                    ]
                  },
                  containers: {
                    data: [
                      { id: { type: :string } },
                      { type: { type: :string } },
                      { attributes: { type: :object } },
                      { relationships: { type: :object } }
                    ]
                  }
                }
              }
            }
          },
          required: ['data']
        )

        run_test!
      end

      response '404', 'when the container cannot be found' do
        let(:id) { 'invalid' }
        run_test!
      end
    end
  end
end
