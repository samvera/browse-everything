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

  after do
    Object.send(:remove_const, :MyDriver)
  end

  describe '#default_sorter' do
    let(:file1) do
      instance_double(BrowseEverything::FileEntry)
    end
    let(:file2) do
      instance_double(BrowseEverything::FileEntry)
    end
    let(:file3) do
      instance_double(BrowseEverything::FileEntry)
    end
    let(:files) do
      [
        file1,
        file2,
        file3
      ]
    end

    before do
      class MyNewDriver < BrowseEverything::Driver::Base; end

      allow(file1).to receive(:container?).and_return(false)
      allow(file1).to receive(:name).and_return('test file1')
      allow(file2).to receive(:container?).and_return(false)
      allow(file2).to receive(:name).and_return('test file2')
      allow(file3).to receive(:container?).and_return(true)
      allow(file3).to receive(:name).and_return('test container1')
    end
    after do
      Object.send(:remove_const, :MyNewDriver)
    end

    it 'defaults to proc which sorts by containers' do
      expect(MyNewDriver.default_sorter).to be_a(Proc)

      results = MyNewDriver.default_sorter.call(files)
      expect(results.first.name).to eq file3.name
      expect(results[1].name).to eq file1.name
      expect(results.last.name).to eq file2.name
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
