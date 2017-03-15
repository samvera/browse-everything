require 'aws-sdk'

module BrowseEverything
  module Driver
    class S3 < Base
      DEFAULTS = { signed_url: true, region: 'us-east-1' }.freeze
      CONFIG_KEYS = [:app_key, :app_secret, :bucket].freeze

      attr_reader :entries

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

      # @return [Array<BrowseEverything::FileEntry>]
      # Appends / to the path before querying S3
      def contents(path = '')
        path = File.join(path, '') unless path.empty?
        init_entries(path)
        generate_listing(path)
        sort_entries
      end

      def generate_listing(path)
        listing = client.list_objects(bucket: config[:bucket], delimiter: '/', prefix: path)
        add_directories(listing)
        add_files(listing, path)
      end

      def add_directories(listing)
        listing.common_prefixes.each do |prefix|
          entries << entry_for(prefix.prefix, 0, Time.current, true)
        end
      end

      def add_files(listing, path)
        listing.contents.reject { |entry| entry.key == path }.each do |entry|
          entries << entry_for(entry.key, entry.size, entry.last_modified, false)
        end
      end

      def sort_entries
        entries.sort do |a, b|
          if b.container?
            a.container? ? a.name.downcase <=> b.name.downcase : 1
          else
            a.container? ? -1 : a.name.downcase <=> b.name.downcase
          end
        end
      end

      def init_entries(path)
        @entries = if path.empty?
                     []
                   else
                     [BrowseEverything::FileEntry.new(Pathname(path).join('..'),
                                                      '',
                                                      '..',
                                                      0,
                                                      Time.current,
                                                      true)]
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
