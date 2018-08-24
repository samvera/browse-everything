# frozen_string_literal: true

describe BrowseEverything do
  shared_examples "a configured BrowseEverything module" do
    describe 'registered configuration' do
      it 'registers the configuration for the drivers' do
        expect(described_class.config).to be_a ActiveSupport::HashWithIndifferentAccess

        expect(described_class.config).to include 'dropbox'
        expect(described_class.config['dropbox']).to include('client_id' => 'test-key')
        expect(described_class.config['dropbox']).to include('client_secret' => 'test-secret')

        expect(described_class.config).to include 'box'
        expect(described_class.config['box']).to include('client_id' => 'test-id')
        expect(described_class.config['box']).to include('client_secret' => 'test-secret')

        expect(described_class.config).to include 'google_drive'
        expect(described_class.config['google_drive']).to include('client_id' => 'test-id')
        expect(described_class.config['google_drive']).to include('client_secret' => 'test-secret')
      end
    end
  end

  describe '.configure' do
    context 'with a hash' do
      let(:config) do
        {
          dropbox: {
            client_id: 'test-key',
            client_secret: 'test-secret'
          },
          box: {
            client_id: 'test-id',
            client_secret: 'test-secret'
          },
          google_drive: {
            client_id: 'test-id',
            client_secret: 'test-secret'
          }
        }
      end

      before do
        described_class.configure(config)
      end

      it_behaves_like 'a configured BrowseEverything module'

      context 'with an entry for the drop_box provider' do
        let(:config) do
          {
            drop_box: {
              app_key: 'test-key',
              app_secret: 'test-secret'
            }
          }
        end

        it 'logs a deprecation warning and sets it to the dropbox key' do
          expect(described_class.config).not_to include 'drop_box'
          expect(described_class.config).to include 'dropbox'
          expect(described_class.config['dropbox']).to include('app_key' => 'test-key')
          expect(described_class.config['dropbox']).to include('app_secret' => 'test-secret')
        end
      end
    end

    context 'with a YAML file' do
      before do
        described_class.configure(File.expand_path('../../fixtures/config/browse_everything_providers.yml', __FILE__))
      end

      it_behaves_like 'a configured BrowseEverything module'
    end
  end

  context 'with an unsupported or invalid configuration' do
    let(:config) { 1234 }

    it 'raises an initialization error' do
      expect { described_class.configure(config) }.to raise_error(BrowseEverything::InitializationError, 'Unrecognized configuration: 1234')
    end
  end
end
