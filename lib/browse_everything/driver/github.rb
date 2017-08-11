module BrowseEverything
  module Driver
    class Github < Base
      require 'octokit'

      def icon
        'github'
      end

      def validate_config
        raise BrowseEverything::InitializationError, 'Octokit driver requires a :access_token argument' unless config[:access_token]
        raise BrowseEverything::InitializationError, 'Octokit driver requires a :repository argument' unless config[:repository]
      end

      def contents(path)
        return to_enum(:contents, path) unless block_given?

        client.contents(repo, path: path).each do |resource|
          yield BrowseEverything::FileEntry.new(resource.path, [key, resource.path].join(':'), resource.name, resource.size, nil, resource.type == 'dir')
        end
      end

      def details(path)
        contents(path).first
      end

      def link_for(path)
        resource = client.contents(repo, path: path)
        [resource.download_url, { file_name: resource.name }]
      end

      def authorized?
        true
      end

      private

        def client
          @client ||= ::Octokit::Client.new(access_token: config[:access_token])
        end

        def repo
          config[:repository]
        end
    end
  end
end
