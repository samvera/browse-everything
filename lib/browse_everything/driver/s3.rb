# frozen_string_literal: true

require 'aws-sdk-s3'
require_relative 'authentication_factory'

module BrowseEverything
  module Driver
    class S3 < Base
      DEFAULTS = { response_type: :signed_url, expires_in: 14400 }.freeze
      RESPONSE_TYPES = %i[signed_url public_url s3_uri].freeze
      CONFIG_KEYS = %i[bucket region].freeze

      class << self
        attr_accessor :authentication_klass

        def default_authentication_klass
          Aws::S3::Client
        end
      end

      attr_reader :entries

      def initialize(config, *args)
        if config.key?(:signed_url)
          warn '[DEPRECATION] Amazon S3 driver: `:signed_url` is deprecated.  Please use `response_type :signed_url` instead.'
          response_type = config.delete(:signed_url) ? :signed_url : :public_url
          config[:response_type] = response_type
        end
        merged_config = DEFAULTS.merge(config)
        self.class.authentication_klass ||= self.class.default_authentication_klass
        super(merged_config, *args)
      end

      def icon
        'amazon'
      end

      def validate_config
        raise InitializationError, 'Amazon S3 driver: If either :app_key or :app_secret is provided, both must be.' if config.values_at(:app_key, :app_secret).compact.length == 1
        raise InitializationError, "Amazon S3 driver: Valid response types: #{RESPONSE_TYPES.join(',')}" unless RESPONSE_TYPES.include?(config[:response_type].to_sym)
        return if CONFIG_KEYS.all? { |key| config[key].present? }
        raise InitializationError, "Amazon S3 driver requires #{CONFIG_KEYS.join(',')}"
      end

      # Retrieve the entries from the S3 Bucket
      # @return [Array<BrowseEverything::FileEntry>]
      def contents(path = '')
        path = File.join(path, '') unless path.empty?
        @entries = []

        generate_listing(path)
        @sorter.call(@entries)
      end

      def link_for(path)
        obj = bucket.object(full_path(path))

        extras = {
          file_name: File.basename(path),
          expires: (config[:expires_in] if config[:response_type] == :signed_url)
        }.compact

        url = case config[:response_type].to_sym
              when :signed_url then obj.presigned_url(:get, expires_in: config[:expires_in])
              when :public_url then obj.public_url
              when :s3_uri     then "s3://#{obj.bucket_name}/#{obj.key}"
              end

        [url, extras]
      end

      def authorized?
        true
      end

      def bucket
        @bucket ||= Aws::S3::Bucket.new(config[:bucket], client: client)
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

      def session
        AuthenticationFactory.new(
          self.class.authentication_klass,
          aws_config
        )
      end

      def authenticate
        session.authenticate
      end

      def client
        @client ||= authenticate
      end

      # Construct a BrowseEverything::FileEntry object
      # @param name [String]
      # @param size [String]
      # @param date [DateTime]
      # @param dir [String]
      # @return [BrowseEverything::FileEntry]
      def entry_for(name, size, date, dir)
        BrowseEverything::FileEntry.new(name, [key, name].join(':'), File.basename(name), size, date, dir)
      end

      # Populate the entries with FileEntry objects from an S3 listing
      # @param listing [Seahorse::Client::Response]
      def add_directories(listing)
        listing.common_prefixes.each do |prefix|
          new_entry = entry_for(from_base(prefix.prefix), 0, Time.current, true)
          @entries << new_entry unless new_entry.nil?
        end
      end

      # Given a listing and a S3 listing and path, populate the entries
      # @param listing [Seahorse::Client::Response]
      # @param path [String]
      def add_files(listing, path)
        listing.contents.each do |entry|
          key = from_base(entry.key)
          new_entry = entry_for(key, entry.size, entry.last_modified, false)
          @entries << new_entry unless strip(key) == strip(path) || new_entry.nil?
        end
      end

      # For a given path to a S3 resource, retrieve the listing object and
      # construct the file entries
      # @param path [String]
      def generate_listing(path)
        client
        listing = client.list_objects(bucket: config[:bucket], delimiter: '/', prefix: full_path(path))
        add_directories(listing)
        add_files(listing, path)
      end
    end
  end
end
