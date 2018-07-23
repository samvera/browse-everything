# frozen_string_literal: true

describe BrowseEverything do
  describe '.configure' do

    let(:config) do
      {
        dropbox: {
          app_key: 'test-key',
          app_secret: 'test-secret'
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
      BrowseEverything.configure(config)
    end
    it 'registers the configuration for the drivers' do
      expect(BrowseEverything.config).to be_a ActiveSupport::HashWithIndifferentAccess

      expect(BrowseEverything.config).to include 'dropbox'
      expect(BrowseEverything.config['dropbox']).to include({ 'app_key' => 'test-key' })
      expect(BrowseEverything.config['dropbox']).to include({ 'app_secret' => 'test-secret' })

      expect(BrowseEverything.config).to include 'box'
      expect(BrowseEverything.config['box']).to include({ 'client_id' => 'test-id' })
      expect(BrowseEverything.config['box']).to include({ 'client_secret' => 'test-secret' })

      expect(BrowseEverything.config).to include 'google_drive'
      expect(BrowseEverything.config['google_drive']).to include({ 'client_id' => 'test-id' })
      expect(BrowseEverything.config['google_drive']).to include({ 'client_secret' => 'test-secret' })
    end

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
        expect(BrowseEverything.config).not_to include 'drop_box'
        expect(BrowseEverything.config).to include 'dropbox'
        expect(BrowseEverything.config['dropbox']).to include({ 'app_key' => 'test-key' })
        expect(BrowseEverything.config['dropbox']).to include({ 'app_secret' => 'test-secret' })
      end
    end
  end

  context 'with an unsupported or invalid configuration' do
    let(:config) { 1234 }

    it 'raises an initialization error' do
      expect { BrowseEverything.configure(config) }.to raise_error(BrowseEverything::InitializationError, 'Unrecognized configuration: 1234')
    end
  end
end
