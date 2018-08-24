# frozen_string_literal: true

describe BrowseEverything::Driver::Paginator::GoogleDrive do
  subject(:paginator) { described_class.new }

  let(:file_entry) { instance_double(BrowseEverything::FileEntry) }
  let(:file_entries) { [file_entry] }

  describe '#[]' do
    before do
      paginator['test-page-token-1'] = file_entries
    end

    it 'retrieves indexed file entries using a page number' do
      expect(paginator['test-page-token-1']).to respond_to(:each)
      expect(paginator['test-page-token-1']).to include(file_entry)
    end
  end

  describe '#[]=' do
    before do
      paginator[described_class::FIRST_PAGE_TOKEN] = file_entries
      paginator['test-page-token-1'] = file_entries
    end

    it 'indexes file entries by page number' do
      expect(paginator.length).to eq(2)
      expect(paginator['test-page-token-1']).to respond_to(:each)
      expect(paginator['test-page-token-1']).to include(file_entry)
    end
  end

  describe '#indexed?' do
    before do
      paginator['test-page-token-1'] = file_entries
      paginator['test-page-token-2'] = []
    end

    it 'determines whether or not a page number has been indexed with at least one file entry' do
      expect(paginator.indexed?('test-page-token-1')).to be true
      expect(paginator.indexed?('test-page-token-2')).to be false
      expect(paginator.indexed?('test-page-token-3')).to be false
    end
  end

  describe '#page_tokens' do
    subject(:paginator) { described_class.new }
    before do
      paginator[described_class::FIRST_PAGE_TOKEN] = file_entries
      paginator['test-page-token-1'] = file_entries
    end

    it 'retrieves all page numbers' do
      expect(paginator.page_tokens).to include described_class::FIRST_PAGE_TOKEN
      expect(paginator.page_tokens).to include 'test-page-token-1'
    end
  end

  describe '#length' do
    before do
      paginator[described_class::FIRST_PAGE_TOKEN] = file_entries
      paginator['test-page-token-1'] = file_entries
      paginator['test-page-token-2'] = file_entries
    end

    it 'calculates the number of pages' do
      expect(paginator.length).to eq(3)
    end
  end

  describe '#first_page?' do
    before do
      paginator[described_class::FIRST_PAGE_TOKEN] = file_entries
    end

    it 'determines whether or not the page index cursor is on the first page' do
      expect(paginator.first_page?).to be true
    end
  end

  describe '#last_page?' do
    subject(:paginator) { described_class.new }
    before do
      paginator[described_class::FIRST_PAGE_TOKEN] = file_entries
      paginator.next_page_token = described_class::LAST_PAGE_TOKEN
    end

    it 'determines whether or not the page index cursor is on the first page' do
      expect(paginator.last_page?).to be true

      paginator.next_page_token = 'test-page-token-2'
      expect(paginator.last_page?).to be false
    end
  end

  describe '#next_page_token=' do
    before do
      paginator[described_class::FIRST_PAGE_TOKEN] = file_entries
      paginator.next_page_token = 'test-page-token-1'
    end

    it 'indexes a new token, updates the page cursor, and populates the pages with empty entries' do
      expect(paginator.length).to eq(2)
      expect(paginator.page_token).to eq('test-page-token-1')
      expect(paginator['test-page-token-1']).to respond_to(:each)
      expect(paginator['test-page-token-1']).to be_empty
    end
  end
end
