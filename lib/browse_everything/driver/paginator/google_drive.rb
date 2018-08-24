# frozen_string_literal: true

module BrowseEverything
  module Driver
    module Paginator
      class GoogleDrive
        FIRST_PAGE_TOKEN = 'START'
        LAST_PAGE_TOKEN = 'END'

        attr_reader :page_token
        def initialize
          new_entries = entries_klass.new([])
          @page_token = FIRST_PAGE_TOKEN
          @structure = { @page_token => new_entries }
        end

        # Retrieve a page of entries
        # @param [String] page_token
        # @return [Entries]
        def [](page_token)
          @structure[page_token]
        end

        # Build the Entries from an Array of FileEntry objects and key them to
        #   an API page token
        # @param [String] page_token
        # @param [Array<BrowseEverything::FileEntry>] values
        # @return [Entries]
        def []=(page_token, values)
          new_entries = entries_klass.new(values)
          @structure[page_token] = new_entries
        end

        # Determines whether or not a page has been indexed into memory using
        #   an API page token
        # @param [String] page_token
        # @return [Boolean]
        def indexed?(page_token)
          entries = @structure[page_token]
          entries.present?
        end

        # Retrieves the page tokens which have been indexed for file entries
        # @return [Array<String>]
        def page_tokens
          @structure.keys
        end

        # Determine the number of pages by using the number of stored page
        #   tokens
        # @return [Integer]
        delegate :length, to: :page_tokens

        # Determines whether or not the current index for the files entries is
        #   on the first page
        # @return [Boolean]
        def first_page?
          @page_token == FIRST_PAGE_TOKEN
        end

        # Determines whether or not the current index for the files entries is
        #   on the last page
        # @return [Boolean]
        def last_page?
          @page_token == LAST_PAGE_TOKEN
        end

        # Indexes a page token as the token for the next page of file entries
        # @param [String] token
        def next_page_token=(token)
          @page_token = token
          @structure[@page_token] = entries_klass.new([])
        end

        private

          # Models the enumerable used for handling sets of file entries
          class Entries < SimpleDelegator; end

          # Defines the Class used to handle sets of file entries
          # @return [Class]
          def entries_klass
            Entries
          end
      end
    end
  end
end
