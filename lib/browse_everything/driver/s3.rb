require 'aws-sdk-s3'

module BrowseEverything
  module Driver
    class S3 < Base
      DEFAULTS = { response_type: :signed_url }.freeze
      RESPONSE_TYPES = [:signed_url, :public_url, :s3_uri].freeze
      CONFIG_KEYS = [:bucket].freeze

      attr_reader :entries

      def initialize(config, *args)
        if config.key?(:signed_url) && config.delete(:signed_url) == false
          warn '[DEPRECATION] Amazon S3 driver: `:signed_url` is deprecated.  Please use `:response_type` instead.'
          config[:response_type] = :public_url
        end
        config = DEFAULTS.merge(config)
        super
      end

      def icon
        'amazon'
      end

      def validate_config
        if config.values_at(:app_key, :app_secret).compact.length == 1
          raise BrowseEverything::InitializationError, 'Amazon S3 driver: If either :app_key or :app_secret is provided, both must be.'
        end
        unless RESPONSE_TYPES.include?(config[:response_type].to_sym)
          raise BrowseEverything::InitializationError, "Amazon S3 driver: Valid response types: #{RESPONSE_TYPES.join(',')}"
        end
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
        listing = client.list_objects(bucket: config[:bucket], delimiter: '/', prefix: full_path(path))
        add_directories(listing)
        add_files(listing, path)
      end

      def add_directories(listing)
        listing.common_prefixes.each do |prefix|
          entries << entry_for(from_base(prefix.prefix), 0, Time.current, true)
        end
      end

      def add_files(listing, path)
        listing.contents.each do |entry|
          key = from_base(entry.key)
          unless strip(key) == strip(path)
            entries << entry_for(key, entry.size, entry.last_modified, false)
          end
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
                     [BrowseEverything::FileEntry.new(Pathname(path).join('..').to_s, '', '..',
                                                      0, Time.current, true)]
                   end
      end

      def entry_for(name, size, date, dir)
        BrowseEverything::FileEntry.new(name, [key, name].join(':'), File.basename(name), size, date, dir)
      end

      def details(path)
        entry = client.head_object(full_path(path))
        BrowseEverything::FileEntry.new(
          entry.key, [key, entry.key].join(':'),
          File.basename(entry.key), entry.size,
          entry.last_modified, false
        )
      end

      def link_for(path)
        obj = bucket.object(full_path(path))
        case config[:response_type].to_sym
        when :signed_url then obj.presigned_url(:get, expires_in: 14400)
        when :public_url then obj.public_url
        when :s3_uri     then "s3://#{obj.bucket_name}/#{obj.key}"
        end
      end

      def authorized?
        true
      end

      def bucket
        @bucket ||= Aws::S3::Bucket.new(config[:bucket], client: client)
      end

      def client
        @client ||= Aws::S3::Client.new(aws_config)
      end

      private

        def strip(path)
          path.sub %r{^/?(.+?)/?$}, '\1'
        end

        def from_base(key)
          Pathname.new(key).relative_path_from(Pathname.new(config[:base].to_s)).to_s
        end

        def full_path(path)
          config[:base].present? ? File.join(config[:base], path) : path
        end

        def aws_config
          result = {}
          result[:credentials] = Aws::Credentials.new(config[:app_key], config[:app_secret]) if config[:app_key].present?
          result[:region] = config[:region] if config.key?(:region)
          result
        end
    end
  end
end
