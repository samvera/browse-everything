# frozen_string_literal: true

describe BrowseEverything::V1::Driver::Base do
  let(:my_driver_class) do
    Class.new do
      include BrowseEverything::V1::Driver::Base

      def get_sorter # rubocop:disable Naming/AccessorMethodName
        sorter
      end
    end
  end

  let(:my_driver) do
    my_driver_class.new
  end

  describe '#sorter' do
    xit 'defaults to nil' do
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
