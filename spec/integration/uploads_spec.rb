# frozen_string_literal: true

require 'swagger_helper'
require 'jwt'

RSpec.describe 'Upload resources', type: :request do
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
  let(:provider_id) { 'file_system' }
  let(:session) do
    created = BrowseEverything::Session.build(provider_id: provider_id, authorization_ids: [authorization_object.id])
    created.save
    created
  end
  let(:session_id) { session.id }

  path '/browse/uploads' do
    get 'retrieves all persisted uploads' do
      security [apiKey: []]
      produces 'application/vnd.api+json'

      response '200', 'uploads exist' do
        schema(type: :object,
               properties: {
                 data: {
                   type: :array,
                   items: [
                     type: :object,
                     properties: {
                       id: { type: :string },
                       type: { type: :string },
                       attributes: {
                         type: :object,
                         properties: {
                           session_id: { type: :string },
                           bytestream_ids: {
                             type: :array

                           },
                           container_ids: {
                             type: :array

                           }
                         }
                       },
                       relationships: {
                         type: :object,
                         properties: {
                           session: {
                             type: :object
                           }
                         }
                       }
                     }
                   ]
                 }
               },
               required: ['data'])
        run_test!
      end
    end

    post 'creates an upload for the selection files for ingest' do
      let(:upload) do
        {
          data: {
            type: 'upload',
            attributes: {
              session_id: session_id
            }
          }
        }
      end

      security [apiKey: []]
      consumes 'application/vnd.api+json'
      produces 'application/vnd.api+json'
      parameter(
        name: :upload,
        in: :body,
        schema: {
          type: :object,
          properties: {
            data: {
              type: :object,
              properties: {
                attributes: {
                  type: :object,
                  properties: {
                    session_id: { type: :string },
                    bytestream_ids: {
                      type: :array,
                      items: [
                        { id: { type: :string } }
                      ]
                    },
                    container_ids: {
                      type: :array,
                      items: [
                        { id: { type: :string } }
                      ]
                    }
                  }
                }
              }
            }
          },
          required: ['data']
        }
      )

      response '201', 'upload was created' do
        schema(type: :object,
               properties: {
                 data: {
                   type: :object,
                   properties: {
                     id: { type: :string },
                     type: { type: :string },
                     attributes: {
                       type: :object,
                       properties: {
                         session_id: { type: :string },
                         bytestream_ids: {
                           type: :array,
                           items: [
                             { id: { type: :string } }
                           ]

                         },
                         container_ids: {
                           type: :array,
                           items: [
                             { id: { type: :string } }
                           ]

                         }
                       }
                     },
                     relationships: {
                       type: :object,
                       properties: {
                         session: {
                           type: :object

                         }

                       }
                     }
                   }
                 }
               },
               required: ['data'])

        run_test!
      end
    end
  end

  path '/browse/uploads/{id}' do
    let(:upload) do
      created = BrowseEverything::Upload.build(session_id: session_id)
      created.save
      created
    end
    let(:id) { upload.id }

    delete 'deletes an existing upload' do
      # Tests #show
      security [apiKey: []]
      produces 'application/vnd.api+json'
      parameter name: :id, in: :path, type: :string

      response '200', 'when the delete is successful' do
      end

      response '404', 'when the upload cannot be found' do
        let(:id) { 'invalid' }
        run_test!
      end
    end

    get 'retrieves an upload for selection files for ingest' do
      security [apiKey: []]
      produces 'application/vnd.api+json'
      parameter name: :id, in: :path, type: :string

      response '200', 'upload exists' do
        schema(type: :object,
               properties: {
                 data: {
                   type: :object,
                   properties: {
                     id: { type: :string },
                     type: { type: :string },
                     attributes: {
                       type: :object,
                       properties: {
                         session_id: { type: :string },
                         bytestream_ids: {
                           type: :array

                         },
                         container_ids: {
                           type: :array

                         }
                       }
                     },
                     relationships: {
                       type: :object,
                       properties: {
                         session: {
                           type: :object

                         }

                       }
                     }
                   }
                 }
               },
               required: ['data'])
        run_test!
      end

      response '404', 'the upload cannot be found' do
        let(:id) { 'invalid' }
        run_test!
      end
    end
  end
end
