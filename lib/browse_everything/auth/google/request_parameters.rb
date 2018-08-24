# frozen_string_literal: true

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
          # order_by: 'modifiedTime desc,folder,name',
          def default_params
            {
              q: default_query,
              order_by: 'folder,name,modifiedTime desc',
              fields: 'nextPageToken,files(name,id,mimeType,size,modifiedTime,parents,web_content_link)',
              supports_team_drives: true,
              include_team_drive_items: true,
              corpora: 'user,allTeamDrives',
              page_size: 1000
            }
          end

          def default_query
            field_queries = []
            contraints.each_pair do |field, constraints|
              field_constraint = constraints.join(" and #{field} ")
              field_queries << "#{field} #{field_constraint}"
            end
            field_queries.join(' and ')
          end

          def contraints
            {
              'mimeType' => [
                '!= \'application/vnd.google-apps.audio\'',
                '!= \'application/vnd.google-apps.document\'',
                '!= \'application/vnd.google-apps.drawing\'',
                '!= \'application/vnd.google-apps.form\'',
                '!= \'application/vnd.google-apps.fusiontable\'',
                '!= \'application/vnd.google-apps.map\'',
                '!= \'application/vnd.google-apps.photo\'',
                '!= \'application/vnd.google-apps.presentation\'',
                '!= \'application/vnd.google-apps.script\'',
                '!= \'application/vnd.google-apps.site\'',
                '!= \'application/vnd.google-apps.spreadsheet\'',
                '!= \'application/vnd.google-apps.video\''
              ]
            }
          end
      end
    end
  end
end
