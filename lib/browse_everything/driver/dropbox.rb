require 'dropbox_sdk'

module BrowseEverything
  module Driver
    class Dropbox < Base
      CONFIG_KEYS = [:app_key, :app_secret].freeze

      def icon
        'dropbox'
      end

      def validate_config
        return if CONFIG_KEYS.all? { |key| config[key].present? }
        raise BrowseEverything::InitializationError, "Dropbox driver requires #{CONFIG_KEYS.inspect}"
      end

      # @return [Array<BrowseEverything::FileEntry>]
      def contents(path = '')
        path.sub!(%r{ /^[\/.]+/}, '')
        result = add_directory_entry(path)
        result += client.metadata(path)['contents'].collect { |info| make_file_entry(info) }
        result
      end

      def add_directory_entry(path)
        return [] if path.empty?
        [BrowseEverything::FileEntry.new(
          Pathname(path).join('..'),
          '', '..', 0, Time.zone.now, true
        )]
      end

      def make_file_entry(info)
        path = info['path']
        BrowseEverything::FileEntry.new(
          path,
          [key, path].join(':'),
          File.basename(path),
          info['bytes'],
          Time.zone.parse(info['modified']),
          info['is_dir']
        )
      end

      def link_for(path)
        [client.media(path)['url'], { expires: 4.hours.from_now, file_name: File.basename(path), file_size: client.metadata(path)['bytes'].to_i }]
      end

      def details(path)
        contents(path).first
      end

      def auth_link
        [auth_flow.start('dropbox'), @csrf]
      end

      def connect(params, data)
        @csrf = data
        @token, _user, _state = auth_flow.finish(params)
        @token
      end

      def authorized?
        token.present?
      end

      private

        def auth_flow
          @csrf ||= {}
          DropboxOAuth2Flow.new(config[:app_key], config[:app_secret], callback.to_s, @csrf, 'token')
        end

        def client
          DropboxClient.new(token)
        end
    end
  end
end
