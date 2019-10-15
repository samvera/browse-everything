require 'swagger_helper'

RSpec.describe 'Container resources', type: :request do

  path '/browse/containers' do
    get 'it retrieves a folder or directory from the provider' do
      produces 'application/vnd.api+json'
      parameter name: :id, :in => :path, :type => :string

      response '200', 'container exists' do
        schema type: :object,
          properties: {
          id: { type: :integer },
          data: [
            {
              attributes: [ { name: { type: :string } } ],
              relationships: {
                bytestreams: { data: [ { id: { type: :string } } ] },
                containers: { data: [ { id: { type: :string } } ] }
              }
            }
          ],
        },
        required: [ 'id', 'data' ]

        let(:id) { 'foo' }
        run_test!
      end

      response '404', 'the container cannot be found' do
        let(:id) { 'invalid' }
        run_test!
      end
    end
  end
end
