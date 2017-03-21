module BrowseEverything
  module Driver
    class SkyDrive < Base
      require 'skydrive'

      def icon
        'windows'
      end

      def container_items
        %w(folder album)
      end

      def validate_config
        unless config[:client_id]
          raise BrowseEverything::InitializationError, 'SkyDrive driver requires a :client_id argument'
        end
        unless config[:client_secret]
          raise BrowseEverything::InitializationError, 'SkyDrive driver requires a :client_secret argument'
        end
      end

      def contents(path = '')
        result = []
        token_obj = rehydrate_token
        client = Skydrive::Client.new(token_obj)
        if path == ''
          folder = client.my_skydrive
        # TODO: do some loop to get down to my path
        else
          folder = client.get("/#{path.tr('-', '.')}/")
          result += [parent_folder_details(folder)] if folder.parent_id
        end

        files = folder.files
        files.items.each do |item|
          if container_items.include? item.type
            result += [folder_details(item)]
          else
            Rails.logger.warn("\n\nID #{item.id} #{item.type}")
            result += [file_details(item)]
          end
        end
        result
      end

      def link_for(path)
        response = Skydrive::Client.new(rehydrate_token).get("/#{real_id(path)}/")
        [response.download_link, { expires: 1.hour.from_now, file_name: File.basename(path), file_size: response.size.to_i }]
      end

      def file_details(file)
        BrowseEverything::FileEntry.new(
          safe_id(file.id),
          "#{key}:#{safe_id(file.id)}",
          file.name,
          file.size,
          file.updated_time,
          false
        )
      end

      def parent_folder_details(file)
        BrowseEverything::FileEntry.new(
          safe_id(file.parent_id),
          "#{key}:#{safe_id(file.parent_id)}",
          '..',
          0,
          Time.now,
          true
        )
      end

      def folder_details(folder)
        BrowseEverything::FileEntry.new(
          safe_id(folder.id),
          "#{key}:#{safe_id(folder.id)}",
          folder.name,
          0,
          folder.updated_time,
          true,
          'directory' # TODO: how are we getting mime type
        )
      end

      def auth_link
        oauth_client.authorize_url
      end

      def authorized?
        return false unless @token.present?
        !rehydrate_token.expired?
      end

      def connect(params, _data)
        Rails.logger.warn "params #{params.inspect}"
        token = oauth_client.get_access_token(params[:code])
        @token = { token: token.token, expires_at: token.expires_at }
      end

      private

        def oauth_client
          Skydrive::Oauth::Client.new(config[:client_id], config[:client_secret], callback.to_s, 'wl.skydrive')
          # TODO: error checking here
        end

        def rehydrate_token
          return @rehydrate_token if @rehydrate_token
          token_str = @token[:token]
          token_expires = @token[:expires_at]
          Rails.logger.warn "\n\n Rehydrating: #{@token} #{token_str} #{token_expires}"
          @rehydrate_token = oauth_client.get_access_token_from_hash(token_str, expires_at: token_expires)
        end

        def safe_id(id)
          id.tr('.', '-')
        end

        def real_id(id)
          id.tr('-', '.')
        end
    end
  end
end
