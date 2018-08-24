# frozen_string_literal: true

describe BrowseEverything::Driver do
  let(:my_driver) do
    MyDriver.new
  end

  before do
    class MyDriver
      include BrowseEverything::Driver

      def get_sorter # rubocop:disable Naming/AccessorMethodName
        sorter
      end
    end
  end

  describe '#sorter' do
    it 'defaults to nil' do
      expect(described_class.sorter).to be nil
    end
  end

  describe '#sorter=' do
    let(:new_sorter) do
      ->(files) {}
    end
    let(:default_sorter) { described_class.sorter }

    before do
      default_sorter
      described_class.sorter = new_sorter
    end

    it 'mutates the sorter from the initializer' do
      expect(my_driver.get_sorter).to eq new_sorter
    end

    after do
      described_class.sorter = default_sorter
    end
  end

  after do
    Object.send(:remove_const, :MyDriver)
  end
end
