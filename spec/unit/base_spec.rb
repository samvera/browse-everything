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
  describe '#details' do
    subject { driver.details('/path/to/foo.txt') }
    it { is_expected.to be_nil }
  end
  describe '#link_for' do
    subject { driver.link_for('/path/to/foo.txt') }
    it { is_expected.to contain_exactly('/path/to/foo.txt', file_name: 'foo.txt') }
  end
end
