# frozen_string_literal: true

describe BrowseEverything::Driver do
  let(:my_driver_class) do
    Class.new do
      include BrowseEverything::Driver

      def get_sorter # rubocop:disable Naming/AccessorMethodName
        sorter
      end
    end
  end

  let(:my_driver) do
    my_driver_class.new
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

    before do
      described_class.sorter = new_sorter
    end

    it 'mutates the sorter from the initializer' do
      expect(my_driver.get_sorter).to eq new_sorter
    end
  end
end
