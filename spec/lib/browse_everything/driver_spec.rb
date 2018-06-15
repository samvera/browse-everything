# frozen_string_literal: true

describe BrowseEverything::Driver do

  let(:my_driver) do
    MyDriver.new
  end

  before do
    class MyDriver
      include BrowseEverything::Driver

      def get_sorter
        sorter
      end
    end
  end

  describe '#sorter' do
    it 'defaults to nil' do
      expect(BrowseEverything::Driver.sorter).to be nil
    end
  end

  describe '#sorter=' do
    let(:new_sorter) do
      lambda { |files| }
    end

    before do
      BrowseEverything::Driver.sorter = new_sorter
    end

    it 'mutates the sorter from the initializer' do
      expect(my_driver.get_sorter).to eq new_sorter
    end
  end
end
