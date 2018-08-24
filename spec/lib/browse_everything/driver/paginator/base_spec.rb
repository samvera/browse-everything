# frozen_string_literal: true

describe BrowseEverything::Driver::Paginator::Base do
  subject(:paginator) { described_class.new }

  let(:file_entry) { instance_double(BrowseEverything::FileEntry) }
  let(:file_entries) { [file_entry] }

  describe '#[]' do
    before do
      paginator[0] = file_entries
    end

    it 'retrieves indexed file entries using a page number' do
      expect(paginator[0]).to respond_to(:each)
      expect(paginator[0]).to include(file_entry)
    end
  end

  describe '#[]=' do
    before do
      paginator[0] = file_entries
      paginator[1] = file_entries
    end

    it 'indexes file entries by page number' do
      expect(paginator.length).to eq(2)
      expect(paginator[1]).to respond_to(:each)
      expect(paginator[1]).to include(file_entry)
    end
  end

  describe '#indexed?' do
    before do
      paginator[0] = file_entries
      paginator[1] = []
    end

    it 'determines whether or not a page number has been indexed with at least one file entry' do
      expect(paginator.indexed?(0)).to be true
      expect(paginator.indexed?(1)).to be false
      expect(paginator.indexed?(2)).to be false
    end
  end

  describe '#page_indices' do
    before do
      paginator[0] = file_entries
      paginator[1] = file_entries
      paginator[3] = file_entries
    end

    it 'retrieves all page numbers' do
      expect(paginator.page_indices).to include 0
      expect(paginator.page_indices).to include 1
      expect(paginator.page_indices).to include 3
    end
  end

  describe '#length' do
    before do
      paginator[0] = file_entries
      paginator[1] = file_entries
      paginator[3] = file_entries
    end

    it 'calculates the number of pages' do
      expect(paginator.length).to eq(3)
    end
  end

  describe '#first_page?' do
    before do
      paginator[0] = file_entries
    end

    it 'determines whether or not the page index cursor is on the first page' do
      expect(paginator.first_page?).to be true
    end
  end

  describe '#last_page?' do
    before do
      paginator[0] = file_entries
    end

    it 'determines whether or not the page index cursor is on the first page' do
      expect(paginator.last_page?).to be true

      paginator[2] = file_entries
      paginator[1] = file_entries
      expect(paginator.last_page?).to be false

      paginator[3] = file_entries
      expect(paginator.last_page?).to be true
    end
  end
end
