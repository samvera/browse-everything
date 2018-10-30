# frozen_string_literal: true

describe BrowseEverything::Retriever do
  let(:retriever) { described_class.new }
  let(:datafile) { File.expand_path('../../fixtures/file_system/file_1.pdf', __dir__) }
  let(:datafile_with_spaces) { File.expand_path('../../fixtures/file_system/file 1.pdf', __dir__) }
  let(:data) { File.open(datafile, 'rb', &:read) }
  let(:data_with_spaces) { File.open(datafile_with_spaces, 'rb', &:read) }
  let(:size) { File.size(datafile) }

  describe '#get_file_size' do
    subject(:computed_file_size) { retriever.file_size(options) }

    let(:url) { URI.parse("file://#{datafile}") }
    let(:headers) { {} }
    let(:file_size) { 0 }
    let(:options) do
      {
        url: url,
        headers: headers,
        file_size: file_size
      }.with_indifferent_access
    end

    it 'calculates or retrieves the size of a file' do
      retriever.retrieve(options) do |_chunk, _retrieved, total|
        expect(total).to eq 2256
      end
    end

    context 'when retrieving a resource from a cloud storage provider' do
      let(:url) { URI.parse('https://drive.google.com/uc?id=id&export=download') }

      before do
        stub_request(
          :head, "https://drive.google.com/uc?export=download&id=id"
        ).and_return(
          headers: {
            'Content-Length' => '1234'
          }
        )

        stub_request(
          :get, "https://drive.google.com/uc?export=download&id=id"
        ).and_return(
          headers: {
            'Content-Length' => '1234'
          },
          body: 'content'
        )
      end

      it 'calculates or retrieves the size of a file' do
        retriever.retrieve(options) do |_chunk, _retrieved, total|
          expect(total).to eq 1234
        end
      end
    end

    context 'when retrieving a resource with an unsupported protocol' do
      let(:url) { URI.parse('ftp://invalid') }

      it 'raises an error' do
        expect { retriever.retrieve(options) { |c, r, t| } }.to raise_error(URI::BadURIError, 'Unknown URI scheme: ftp')
      end
    end
  end

  context 'with a non-URI' do
    let(:spec) do
      {
        '0' => {
          'url' => '/some/dir/file.pdf',
          'file_name' => 'file.pdf',
          'file_size' => size.to_s
        }
      }
    end

    describe '#retrieve' do
      it 'raises an error' do
        expect { retriever.retrieve(spec['0']) }.to raise_error(URI::BadURIError)
      end
    end
  end

  context 'when retrieving using the HTTP' do
    let(:expiry_time) { (Time.current + 3600).xmlschema }
    let(:spec) do
      {
        '0' => {
          'url' => 'https://retrieve.cloud.example.com/some/dir/file.pdf',
          'auth_header' => { 'Authorization' => 'Bearer ya29.kQCEAHj1bwFXr2AuGQJmSGRWQXpacmmYZs4kzCiXns3d6H1ZpIDWmdM8' },
          'expires' => expiry_time,
          'file_name' => 'file.pdf',
          'file_size' => size.to_s
        }
      }
    end

    context 'when retrieving data using chunked-encoded streams' do
      before do
        stub_request(
          :get, "https://retrieve.cloud.example.com/some/dir/file.pdf"
        ).and_return(
          headers: {
            'Content-Type' => 'text/plain'
          },
          body: data
        )
      end

      it 'content' do
        content = +''
        retriever.retrieve(spec['0']) { |chunk, _retrieved, _total| content << chunk }
        expect(content).to eq(data)
      end

      it 'callbacks' do
        expect { |block| retriever.retrieve(spec['0'], &block) }.to yield_with_args(data, data.length, data.length)
      end
    end

    context 'when downloading content' do
      before do
        stub_request(
          :get, "https://retrieve.cloud.example.com/some/dir/file.pdf"
        ).and_return(
          headers: {
            'Content-Type' => 'text/plain'
          },
          body: data
        )
      end

      it 'content' do
        file = retriever.download(spec['0'])
        expect(File.open(file, 'rb', &:read)).to eq(data)
      end

      it 'callbacks' do
        expect { |block| retriever.download(spec['0'], &block) }.to yield_with_args(String, data.length, data.length)
      end
    end

    context 'when downloading content and a server error occurs' do
      let(:spec) do
        {
          '0' => {
            'url' => 'https://retrieve.cloud.example.com/some/dir/file_error.pdf',
            'auth_header' => { 'Authorization' => 'Bearer ya29.kQCEAHj1bwFXr2AuGQJmSGRWQXpacmmYZs4kzCiXns3d6H1ZpIDWmdM8' },
            'expires' => expiry_time,
            'file_name' => 'file.pdf',
            'file_size' => size.to_s
          }
        }
      end
      let(:download_options) { spec['0'] }
      before do
        stub_request(
          :get, "https://retrieve.cloud.example.com/some/dir/file_error.pdf"
        ).and_return(
          status: 403
        )
      end

      it 'raises an exception' do
        expect { retriever.download(download_options) }.to raise_error(BrowseEverything::DownloadError, /BrowseEverything::Retriever: Failed to download/)
      end
    end
  end

  context 'when retrieving file content' do
    let(:spec) do
      {
        '0' => {
          'url' => "file://#{datafile}",
          'file_name' => 'file.pdf',
          'file_size' => size.to_s
        },
        '1' => {
          'url' => "file://#{datafile_with_spaces}",
          'file_name' => 'file.pdf',
          'file_size' => size.to_s
        }
      }
    end

    context 'when retrieving data using chunked-encoded streams' do
      it 'content' do
        content = +''
        retriever.retrieve(spec['0']) { |chunk, _retrieved, _total| content << chunk }
        expect(content).to eq(data)
      end

      it 'content with spaces' do
        content = +''
        retriever.retrieve(spec['1']) { |chunk, _retrieved, _total| content << chunk }
        expect(content).to eq(data_with_spaces)
      end

      it 'callbacks' do
        expect { |block| retriever.retrieve(spec['0'], &block) }.to yield_with_args(data, data.length, data.length)
      end
    end

    context 'when downloading content' do
      it 'content' do
        file = retriever.download(spec['0'])
        expect(File.open(file, 'rb', &:read)).to eq(data)
      end

      it 'callbacks' do
        expect { |block| retriever.download(spec['0'], &block) }.to yield_with_args(String, data.length, data.length)
      end
    end
  end

  describe '.can_retrieve?' do
    let(:expiry_time) { (Time.current + 3600).xmlschema }
    let(:spec) do
      {
        '0' => {
          'url' => url,
          'auth_header' => { 'Authorization' => 'Bearer ya29.kQCEAHj1bwFXr2AuGQJmSGRWQXpacmmYZs4kzCiXns3d6H1ZpIDWmdM8' },
          'expires' => expiry_time,
          'file_name' => 'file.pdf',
          'file_size' => '64134'
        }
      }
    end

    context 'when can retrieve' do
      let(:url) { 'https://retrieve.cloud.example.com/some/dir/can_retrieve.pdf' }
      before do
        stub_request(
          :get, "https://retrieve.cloud.example.com/some/dir/can_retrieve.pdf"
        ).to_return(
          status: 206,
          body: '%'
        )
      end

      it 'says it can' do
        expect(described_class).to be_can_retrieve(url)
      end
    end

    context 'when cannot retrieve' do
      let(:url) { 'https://retrieve.cloud.example.com/some/dir/cannot_retrieve.pdf' }
      before do
        stub_request(
          :get, "https://retrieve.cloud.example.com/some/dir/cannot_retrieve.pdf"
        ).to_return(
          status: 403
        )
      end

      it 'says it cannot' do
        expect(described_class).not_to be_can_retrieve(url)
      end
    end
  end
end
