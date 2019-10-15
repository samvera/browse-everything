require 'swagger_helper'

RSpec.describe 'Session resources', type: :request do

  path '/browse/sessions' do
    post 'creates a session for the selection files for ingest' do
      consumes 'application/vnd.api+json'
      produces 'application/vnd.api+json'
      parameter name: :session, in: :body, schema: {
        type: :object,
        properties: {
          attributes: {
            provider_id: { type: :string }
          }
        },
        required: [ 'attributes' ]
      }

      response '201', 'session was created' do
        schema type: :object,
          properties: {
            id: { type: :integer },
            data: {
              attributes: [ { name: { type: :string } } ],
              relationships: {
                authorizations: [ { data: [ { id: { type: :string } } ] } ],
                provider: { data: [ { id: { type: :string } } ] }
              }
            }
          },
          required: [ 'id', 'data' ]

        run_test!
      end
    end

    get 'retrieves a session for selection files for ingest' do
      produces 'application/vnd.api+json'
      parameter name: :id, :in => :path, :type => :string

      response '200', 'session exists' do
        schema type: :object,
          properties: {
            id: { type: :integer },
            data: {
              attributes: [ { name: { type: :string } } ],
              relationships: {
                authorizations: [ { data: [ { id: { type: :string } } ] } ],
                provider: { data: [ { id: { type: :string } } ] }
              }
            }
          },
          required: [ 'id', 'data' ]
        let(:id) { 'foo' }
        run_test!
      end

      response '404', 'the session cannot be found' do
        let(:id) { 'invalid' }
        run_test!
      end
    end
  end
end
