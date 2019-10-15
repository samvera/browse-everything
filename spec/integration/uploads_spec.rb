require 'swagger_helper'

RSpec.describe 'Upload resources', type: :request do

  path '/browse/upload' do
    post 'creates an upload for the selection files for ingest' do
      consumes 'application/vnd.api+json'
      produces 'application/vnd.api+json'
      parameter name: :upload, in: :body, schema: {
        type: :object,
        properties: {
          attributes: {
            session_id: { type: :string },
            bytestream_ids: [ { id: { type: :string } } ],
            container_ids: [ { id: { type: :string } } ]
          }
        },
        required: [ 'attributes' ]
      }

      response '201', 'upload was created' do
        schema type: :object,
          properties: {
            id: { type: :integer },
            data: {
              attributes: {
                session_id: { type: :string },
                bytestream_ids: [ { id: { type: :string } } ],
                container_ids: [ { id: { type: :string } } ]
              }
            }
          },
          required: [ 'id', 'data' ]

        run_test!
      end
    end

    get 'retrieves an upload for selection files for ingest' do
      produces 'application/vnd.api+json'
      parameter name: :id, :in => :path, :type => :string

      response '200', 'upload exists' do
        schema type: :object,
          properties: {
            id: { type: :integer },
            data: {
              attributes: {
                session_id: { type: :string },
                bytestream_ids: [ { id: { type: :string } } ],
                container_ids: [ { id: { type: :string } } ]
              }
            }
          },

          required: [ 'id', 'data' ]
        let(:id) { 'foo' }
        run_test!
      end

      response '404', 'the upload cannot be found' do
        let(:id) { 'invalid' }
        run_test!
      end
    end
  end
end
