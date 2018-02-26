# Manages request parameters for the request to the Google Drive API
module BrowseEverything
  module Auth
    module Google
      class RequestParameters < OpenStruct
        # Overrides the constructor for an OpenStruct instance
        # Provides default parameters
        def initialize(params = {})
          @params = default_params.merge(params)
          super(@params)
        end

        private

          # The default query parameters for the Google Drive API
          # @return [Hash]
          def default_params
            {
              order_by: 'folder desc,modifiedTime desc,name',
              fields: 'nextPageToken,files(name,id,mimeType,size,modifiedTime,parents,web_content_link)',
              page_size: 1000
            }
          end
      end
    end
  end
end
