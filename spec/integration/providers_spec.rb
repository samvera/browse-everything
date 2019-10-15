require 'swagger_helper'

RSpec.describe 'Provider resources', type: :request do

  path '/browse/providers' do
    get 'it retrieves a listing of all providers configured for the API' do
      produces 'application/vnd.api+json'

      response '200', 'there are providers available' do
        schema type: :object,
          properties: {
          data: [
            {
              id: { type: :integer },
              attributes: [ { name: { type: :string } } ],
              links: {
                authorization_url: {
                  scheme: { type: :string },
                  host: { type: :string },
                  path: { type: :string },
                  query: { type: :string }
                },
              }
            }
          ],
        },
        required: [ 'data' ]

        run_test!
      end
    end
  end
end
