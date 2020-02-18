require 'swagger_helper'

RSpec.describe 'Provider resources', type: :request do
  path '/browse/providers/{id}' do
    let(:id) { 'file_system' }

    get 'it retrieves a provider by its ID' do
      produces 'application/vnd.api+json'
      parameter name: :id, :in => :path, :type => :string

      response '200', 'there are providers available' do
        schema type: :object,
          properties: {
          data: {
            type: :object,
            properties: {
              id: { type: :string },
              type: { type: :string },
              attributes: {
                id: { type: :string },
                name: { type: :string }
              },
              links: {
                authorization_url: {
                  scheme: { type: :string },
                  host: { type: :string },
                  path: { type: :string },
                  query: { type: :string },
                  user: { type: :string },
                  password: { type: :string },
                  fragment: { type: :string }
                }
              }
            }
          }
        },
        required: [ 'data' ]

        run_test!
      end
    end
  end

  # index Action
  path '/browse/providers' do
    get 'it retrieves a listing of all providers configured for the API' do
      produces 'application/vnd.api+json'

      response '200', 'there are providers available' do
        schema type: :object,
          properties: {
            data: {
              type: :array,
              items: [
                {
                  id: { type: :string },
                  type: { type: :string },
                  attributes: {
                    id: { type: :string },
                    name: { type: :string }
                  },
                  links: {
                    authorization_url: {
                      scheme: { type: :string },
                      host: { type: :string },
                      path: { type: :string },
                      query: { type: :string },
                      user: { type: :string },
                      password: { type: :string },
                      fragment: { type: :string }
                    }
                  }
                }
              ]
            }
          },
          required: [ 'data' ]

        run_test!
      end
    end
  end
end
