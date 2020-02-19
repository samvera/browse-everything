# frozen_string_literal: true

describe BrowseEverything::V1::Driver::Base do
  let(:my_driver) do
    described_class.new({})
  end

  describe '#sorter' do
    it 'defaults to nil' do
      expect(my_driver.sorter).to be_a(Proc)
    end
  end

  describe '#sorter=' do
    let(:new_sorter) do
      ->(files) {}
    end

    before do
      my_driver.sorter = new_sorter
    end

    it 'mutates the sorter from the initializer' do
      expect(my_driver.sorter).to eq new_sorter
    end
  end
end
