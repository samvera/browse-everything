# frozen_string_literal: true

include BrowserConfigHelper

describe BrowseEverything::Driver::Base do
  let(:driver) { described_class.new({}) }

  describe 'simple properties' do
    subject { driver }

    its(:name)      { is_expected.to eq('Base')         }
    its(:key)       { is_expected.to eq('base')         }
    its(:icon)      { is_expected.to be_a(String)      }
    its(:auth_link) { is_expected.to be_empty          }
    specify         { is_expected.not_to be_authorized }
  end

  describe '#connect' do
    subject { driver.connect({}, {}) }

    it { is_expected.to be_blank }
  end

  describe '#contents' do
    subject { driver.contents('') }

    it { is_expected.to be_empty }
  end

  describe '#link_for' do
    subject { driver.link_for('/path/to/foo.txt') }

    it { is_expected.to contain_exactly('/path/to/foo.txt', file_name: 'foo.txt') }
  end

  describe '#contents_next_page' do
    it 'accesses the next or first page token' do
      expect(driver.contents_next_page(nil)).to eq(1)
    end
  end

  describe '#contents_last_page?' do
    it 'determines whether the current page is the last page' do
      expect(driver.contents_last_page?(nil)).to be true
    end
  end
end
