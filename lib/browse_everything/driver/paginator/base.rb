# frozen_string_literal: true

module BrowseEverything
  module Driver
    module Paginator
      class Base
        FIRST_PAGE_INDEX = 0

        def initialize
          new_entries = entries_klass.new([])
          @page_index = FIRST_PAGE_INDEX
          @structure = { @page_index => new_entries }
        end

        # Retrieve a page of entries
        # @param [Integer] page_index
        # @return [Entries]
        def [](page_index)
          @structure[page_index]
        end

        # Build the Entries from an Array of FileEntry objects and key them to
        #   an API page token
        # @param [Integer] page_index
        # @param [Array<BrowseEverything::FileEntry>] values
        # @return [Entries]
        def []=(page_index, values)
          @page_index = page_index
          new_entries = entries_klass.new(values)
          @structure[@page_index] = new_entries
        end

        # Determines whether or not a page has been indexed into memory using
        #   an API page token
        # @param [Integer] page_index
        # @return [Boolean]
        def indexed?(page_index)
          entries = @structure[page_index]
          entries.present?
        end

        # Retrieves the page numbers which have been indexed for file entries
        # @return [Array]
        def page_indices
          @structure.keys
        end

        # Determine the number of pages by using the number of stored page
        #   tokens
        # @return [Integer]
        delegate :length, to: :page_indices

        # Determines whether or not the current index for the files entries is
        #   on the first page
        # @return [Boolean]
        def first_page?
          @page_index == FIRST_PAGE_INDEX
        end

        # Determines whether or not the current index for the files entries is
        #   on the last page
        # @return [Boolean]
        def last_page?
          @page_index == length - 1
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
