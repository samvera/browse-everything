# frozen_string_literal: true

require 'swagger_helper'
require 'jwt'

RSpec.describe 'Authorizations resources', type: :request do
  let(:code) { 'test_auth_code' }
  # This is a magic variable name, rswag needs it to stay authorization
  let(:authorization) do
    created = BrowseEverything::Authorization.build(code: code)
    created.save
    created
  end
  let(:id) { authorization.id }

  path '/browse/authorizations/{id}' do
    delete 'retrieves an existing session' do
      # Tests #destroy
      security [apiKey: []]
      produces 'application/vnd.api+json'
      parameter name: :id, in: :path, type: :string

      response '200', 'delete was successful' do
      end

      response '404', 'when the authorization cannot be found' do
        let(:id) { 'invalid' }
        run_test!
      end
    end

    get 'it retrieves an established authorization' do
      security [apiKey: []]
      produces 'application/vnd.api+json'
      parameter name: :id, in: :path, type: :string

      response '200', 'when the authorization is successfully created' do
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
                    code: { type: :string }
                  },
                  required: ['code']
                },
                required: %w[id type attributes]
              }
            },
            required: ['data']
          }
        )

        run_test!
      end

      response '404', 'when the authorization cannot be found' do
        let(:id) { 'invalid' }
        run_test!
      end
    end
  end
end
