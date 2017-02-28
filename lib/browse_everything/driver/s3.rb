require 'aws-sdk'

module BrowseEverything
  module Driver
    class S3 < Base
      DEFAULTS = { signed_url: true, region: 'us-east-1' }.freeze
      CONFIG_KEYS = [:app_key, :app_secret, :bucket].freeze

      def initialize(config, *args)
        config = DEFAULTS.merge(config)
        super
      end

      def icon
        'amazon'
      end

      def validate_config
        return if CONFIG_KEYS.all? { |key| config[key].present? }
        raise BrowseEverything::InitializationError, "Amazon S3 driver requires #{CONFIG_KEYS.join(',')}"
      end

      def contents(path = '')
        path = File.join(path, '') unless path.empty?
        result = []
        listing = client.list_objects(bucket: config[:bucket], delimiter: '/', prefix: path)
        unless path.empty?
          result << BrowseEverything::FileEntry.new(
            Pathname(path).join('..'),
            '', '..', 0, Time.current, true
          )
        end
        listing.common_prefixes.each do |prefix|
          result << entry_for(prefix.prefix, 0, Time.current, true)
        end
        listing.contents.reject { |entry| entry.key == path }.each do |entry|
          result << entry_for(entry.key, entry.size, entry.last_modified, false)
        end
        result.sort do |a, b|
          if b.container?
            a.container? ? a.name.downcase <=> b.name.downcase : 1
          else
            a.container? ? -1 : a.name.downcase <=> b.name.downcase
          end
        end
      end

      def entry_for(name, size, date, dir)
        BrowseEverything::FileEntry.new(name, [key, name].join(':'), File.basename(name), size, date, dir)
      end

      def details(path)
        entry = client.head_object(path)
        BrowseEverything::FileEntry.new(
          entry.key,
          [key, entry.key].join(':'),
          File.basename(entry.key),
          entry.size,
          entry.last_modified,
          false
        )
      end

      def link_for(path)
        obj = bucket.object(path)
        if config[:signed_url]
          obj.presigned_url(:get, expires_in: 14400)
        else
          obj.public_url
        end
      end

      def authorized?
        true
      end

      def bucket
        @bucket ||= Aws::S3::Bucket.new(config[:bucket], client: client)
      end

      def client
        @client ||= Aws::S3::Client.new(credentials: Aws::Credentials.new(config[:app_key], config[:app_secret]), region: config[:region])
      end
    end
  end
end
