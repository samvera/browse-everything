# frozen_string_literal: true

require 'swagger_helper'
require 'jwt'

RSpec.describe 'Session resources', type: :request do
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

  path '/browse/sessions' do
    # Tests #create
    post 'creates a session for the selection files for ingest' do
      let(:session) do
        {
          data: {
            type: 'session',
            attributes: {
              provider_id: 'file_system'
            }
          }
        }
      end
      security [apiKey: []]

      consumes 'application/vnd.api+json'
      produces 'application/vnd.api+json'
      parameter(
        name: :session,
        in: :body,
        schema: {
          type: :object,
          properties: {
            data: {
              type: :object,
              properties: {
                type: { type: 'string' },
                attributes: {
                  provider_id: { type: :string }
                }
              }
            }
          },
          required: ['data']
        }
      )

      response '201', 'session was created' do
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
                    provider_id: { type: :string },
                    authorization_ids: {
                      type: :array,
                      items: [
                        { type: :string }
                      ]
                    }
                  }
                },
                relationships: {
                  type: :object,
                  properties: {
                    provider: {
                      type: :object,
                      properties: {
                        data: {
                          type: :object,
                          properties: {
                            id: { type: :string },
                            type: { type: :string }
                          }
                        }
                      }
                    },
                    authorizations: {
                      type: :object,
                      properties: {
                        data: {
                          type: :array,
                          items: [
                            id: { type: :string },
                            type: { type: :string }
                          ]
                        }
                      }
                    }
                  }
                }
              },
              required: ['id']
            }
          },
          required: ['data']
        )

        run_test!
      end
    end
  end

  path '/browse/sessions' do
    let(:provider_id) { 'file_system' }
    # This is a magic variable name, rswag needs it to stay authorization
    let(:authorization_object) do
      created = BrowseEverything::Authorization.build
      created.save
      created
    end
    let(:session) do
      created = BrowseEverything::Session.build(provider_id: provider_id, authorization_ids: [authorization_object.id])
      created.save
      created
    end
    let(:session2) do
      created = BrowseEverything::Session.build(provider_id: provider_id, authorization_ids: [authorization_object.id])
      created.save
      created
    end

    before do
      session
      session2
    end

    get 'retrieves all existing sessions' do
      # Tests #index
      security [apiKey: []]
      produces 'application/vnd.api+json'

      response '200', 'session exists' do
        schema(
          type: :object,
          properties: {
            data: {
              type: :array,
              items: [
                properties: {
                  relationships: {
                    provider: {
                      data: [
                        { id: { type: :string } },
                        { type: { type: :string } },
                        { attributes: { type: :object } }
                      ]
                    },
                    authorizations: {
                      data: [
                        { id: { type: :string } },
                        { type: { type: :string } },
                        { attributes: { type: :object } }
                      ]
                    }
                  }
                }
              ]
            }
          },
          required: ['data']
        )
        run_test!
      end
    end
  end

  path '/browse/sessions/{id}' do
    let(:provider_id) { 'file_system' }
    # This is a magic variable name, rswag needs it to stay authorization
    let(:authorization_object) do
      created = BrowseEverything::Authorization.build
      created.save
      created
    end
    let(:session) do
      created = BrowseEverything::Session.build(provider_id: provider_id, authorization_ids: [authorization_object.id])
      created.save
      created
    end
    let(:id) { session.id }

    delete 'retrieves an existing session' do
      # Tests #destroy
      security [apiKey: []]
      produces 'application/vnd.api+json'
      parameter name: :id, in: :path, type: :string

      response '200', 'session exists' do
      end

      response '404', 'when the container cannot be found' do
        let(:id) { 'invalid' }
        run_test!
      end
    end

    get 'retrieves an existing session' do
      # Tests #show
      security [apiKey: []]
      produces 'application/vnd.api+json'
      parameter name: :id, in: :path, type: :string

      response '200', 'session exists' do
        schema(
          type: :object,
          properties: {
            data: {
              type: :object,
              properties: {
                relationships: {
                  provider: {
                    data: [
                      { id: { type: :string } },
                      { type: { type: :string } },
                      { attributes: { type: :object } }
                    ]
                  },
                  authorizations: {
                    data: [
                      { id: { type: :string } },
                      { type: { type: :string } },
                      { attributes: { type: :object } }
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
