# frozen_string_literal: true

include BrowserConfigHelper

describe BrowseEverything::Driver::S3 do
  subject { provider }

  let(:browser)  { BrowseEverything::Browser.new(url_options) }
  let(:provider) { browser.providers['s3'] }

  before do
    stub_configuration
  end

  after do
    unstub_configuration
  end

  describe 'defaults' do
    its(:icon)   { is_expected.to eq('amazon')  }
    its(:itself) { is_expected.to be_authorized }
  end

  describe 'configuration' do
    it 'rejects an empty config.' do
      expect { described_class.new({}) }.to raise_error(BrowseEverything::InitializationError)
    end

    it 'rejects a missing region' do
      expect { described_class.new(bucket: 'bucket', app_key: 'APP_KEY') }.to raise_error(BrowseEverything::InitializationError)
    end

    it 'rejects app_key if app_secret is missing' do
      expect { described_class.new(bucket: 'bucket', region: 'us-east-1', app_key: 'APP_KEY') }.to raise_error(BrowseEverything::InitializationError)
    end

    it 'rejects app_secret if app_key is missing' do
      expect { described_class.new(bucket: 'bucket', region: 'us-east-1', app_secret: 'APP_SECRET') }.to raise_error(BrowseEverything::InitializationError)
    end

    it 'accepts app_key and app_secret together' do
      expect { described_class.new(bucket: 'bucket', region: 'us-east-1', app_key: 'APP_KEY', app_secret: 'APP_SECRET') }.not_to raise_error
    end

    it 'rejects an invalid response type' do
      expect { described_class.new(bucket: 'bucket', region: 'us-east-1', response_type: :foo) }.to raise_error(BrowseEverything::InitializationError)
    end

    context 'deprecating :signed_url' do
      it 'sets the value of :signed_url to :response_type' do
        driver = described_class.new(bucket: 'bucket', region: 'us-east-1', signed_url: false)
        expect(driver.config).not_to have_key(:signed_url)
        expect(driver.config[:response_type]).to eq(:public_url)

        signed_driver = described_class.new(bucket: 'bucket', region: 'us-east-1', signed_url: true)
        expect(signed_driver.config).not_to have_key(:signed_url)
        expect(signed_driver.config[:response_type]).to eq(:signed_url)
      end

      it 'sets the default value of :response_type to :signed_url' do
        driver = described_class.new(bucket: 'bucket', region: 'us-east-1')
        expect(driver.config).not_to have_key(:signed_url)
        expect(driver.config[:response_type]).to eq(:signed_url)
      end
    end
  end

  describe '#contents' do
    context 'when in a root directory' do
      before do
        Aws.config[:s3] = {
          stub_responses: {
            list_objects: { is_truncated: false, marker: '', next_marker: nil, contents: [], name: 's3.bucket', prefix: '', delimiter: '/', max_keys: 1000, common_prefixes: [{ prefix: 'foo/' }, { prefix: 'bar/' }], encoding_type: 'url' }
          }
        }
      end

      let(:contents) { provider.contents('') }

      context 'with a single asset' do
        subject { contents[0] }

        its(:name) { is_expected.to eq('bar') }
        specify    { is_expected.to be_container }
      end

      context 'with two assets' do
        subject { contents[1] }

        its(:name) { is_expected.to eq('foo') }
        specify    { is_expected.to be_container }
      end
    end

    context 'when in a subdirectory' do
      before do
        Aws.config[:s3] = {
          stub_responses: {
            list_objects:
              {
                is_truncated: false, marker: '', next_marker: nil, name: 's3.bucket', prefix: 'foo/', delimiter: '/', max_keys: 1000, common_prefixes: [], encoding_type: 'url',
                contents: [
                  { key: 'foo/', last_modified: Time.zone.parse('2014-02-03 16:27:01 UTC'), etag: '"d41d8cd98f00b204e9800998ecf8427e"', size: 0, storage_class: 'STANDARD', owner: { display_name: 'mbklein' } },
                  { key: 'foo/baz.jpg', last_modified: Time.zone.parse('2016-10-31 20:12:32 UTC'), etag: '"4e2ad532e659a65e8f106b350255a7ba"', size: 52645, storage_class: 'STANDARD', owner: { display_name: 'mbklein' } },
                  { key: 'foo/quux.png', last_modified: Time.zone.parse('2016-10-31 22:08:12 UTC'), etag: '"a92bbe23736ebdbd37bdc795e7d570ad"', size: 1_511_860, storage_class: 'STANDARD', owner: { display_name: 'mbklein' } }
                ]
              }
          }
        }
      end

      let(:contents) { provider.contents('foo/') }

      context 'with a JPEG asset' do
        subject { contents[0] }

        its(:name)     { is_expected.to eq('baz.jpg') }
        its(:location) { is_expected.to eq('s3:foo/baz.jpg')  }
        its(:type)     { is_expected.to eq('image/jpeg')      }
        its(:size)     { is_expected.to eq(52645)             }
        specify        { is_expected.not_to be_container }
      end

      context 'with a PNG asset' do
        subject { contents[1] }

        its(:name)     { is_expected.to eq('quux.png') }
        its(:location) { is_expected.to eq('s3:foo/quux.png') }
        its(:type)     { is_expected.to eq('image/png')       }
        its(:size)     { is_expected.to eq(1_511_860) }
        specify        { is_expected.not_to be_container }
      end

      context 'when retrieving the link for an asset' do
        subject { contents[2] }

        let(:signed_at) { Time.now.utc.change(usec: 0) }
        let(:presigned_url) do
          "https://s3.amazonaws.com/presigned_url?X-Amz-Date=#{signed_at.strftime('%Y%m%dT%H%M%SZ')}&X-Amz-Expires=3600"
        end

        before do
          object = instance_double(Aws::S3::Object)
          allow(object).to receive(:presigned_url).and_return(presigned_url)
          allow(object).to receive(:public_url).and_return('https://s3.amazonaws.com/public_url')
          allow(object).to receive(:bucket_name).and_return('s3.bucket')
          allow(object).to receive(:key).and_return('foo/quux.png')
          allow(object).to receive(:content_length).and_return(1_511_860)
          allow(provider.bucket).to receive(:object).and_return(object)
        end

        it ':signed_url' do
          provider.config[:response_type] = :signed_url
          expect(provider.link_for('foo/quux.png')).to eq [presigned_url, { file_name: 'quux.png', file_size: 1_511_860, expires: signed_at + 3600 }]
        end

        it ':signed_url reports the lifetime the URL was signed for, not expires_in' do
          provider.config[:response_type] = :signed_url
          provider.config[:expires_in] = 14400
          expect(provider.link_for('foo/quux.png').last[:expires]).to eq signed_at + 3600
        end

        it ':signed_url configured as a string still sends the expiry' do
          provider.config[:response_type] = 'signed_url'
          expect(provider.link_for('foo/quux.png').last[:expires]).to eq signed_at + 3600
        end

        [Aws::S3::Errors::Forbidden.new(nil, 'Forbidden'), Seahorse::Client::NetworkingError.new(Errno::ECONNRESET.new)].each do |error|
          it "leaves out the size when reading it raises #{error.class}" do
            provider.config[:response_type] = :s3_uri
            allow(provider.bucket.object('foo/quux.png')).to receive(:content_length).and_raise(error)
            expect(provider.link_for('foo/quux.png')).to eq ['s3://s3.bucket/foo/quux.png', { file_name: 'quux.png' }]
          end
        end

        it ':s3_uri keeps a key that is not a valid URI' do
          provider.config[:response_type] = :s3_uri
          allow(provider.bucket.object('foo/quux.png')).to receive(:key).and_return('foo/résumé file.pdf')
          expect(provider.link_for('foo/quux.png').first).to eq 's3://s3.bucket/foo/résumé file.pdf'
        end

        it ':signed_url gives an expiry the retriever accepts' do
          provider.config[:response_type] = :signed_url
          url, extras = provider.link_for('foo/quux.png')
          spec = { 'url' => url, 'expires' => extras[:expires].to_s, 'file_size' => extras[:file_size] }
          retriever = BrowseEverything::Retriever.new
          allow(retriever).to receive(:retrieve_http)
          expect { retriever.retrieve(spec) }.not_to raise_error
        end

        it ':public_url' do
          provider.config[:response_type] = :public_url
          expect(provider.link_for('foo/quux.png')).to eq ['https://s3.amazonaws.com/public_url', { file_name: 'quux.png', file_size: 1_511_860 }]
        end

        it ':s3_uri' do
          provider.config[:response_type] = :s3_uri
          expect(provider.link_for('foo/quux.png')).to eq ['s3://s3.bucket/foo/quux.png', { file_name: 'quux.png', file_size: 1_511_860 }]
        end
      end
    end
  end
end
