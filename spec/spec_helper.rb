# frozen_string_literal: true

ENV['RAILS_ENV'] ||= 'test'
require 'bundler/setup'

require 'engine_cart'
require File.expand_path('config/environment', EngineCart.destination)
EngineCart.load_application!

require 'capybara/rails'
require 'capybara/rspec'
require 'rspec'
require 'rspec/rails'
require 'rspec/its'
require 'webdrivers'

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[Pathname.new(File.expand_path('support/**/*.rb', __dir__))].each { |f| require f }

require 'webmock/rspec'
WebMock.disable_net_connect!(allow_localhost: true)

RSpec.configure do |config|
  config.before(:each, type: :feature) { WebMock.disable! }
  config.after(:each, type: :feature) do
    WebMock.enable!
    WebMock.disable_net_connect!(allow_localhost: true)
  end

  config.expect_with :rspec do |c|
    c.syntax = %i[should expect]
  end
  config.include WaitForAjax, type: :feature
end

module BrowserConfigHelper
  def url_options
    {
      protocol: 'http://',
      host: 'browse-everything.example.edu',
      script_name: ''
    }
  end

  def stub_configuration
    BrowseEverything.configure('file_system' => {
                                 home: File.expand_path('fixtures/file_system', __dir__)
                               },
                               'box' => {
                                 client_id: 'BoxClientId',
                                 client_secret: 'BoxClientSecret'
                               },
                               'dropbox' => {
                                 client_id: 'DropboxId',
                                 client_secret: 'DropboxClientSecret'
                               },
                               'google_drive' => {
                                 client_id: 'GoogleClientId',
                                 client_secret: 'GoogleClientSecret'
                               },
                               's3' => {
                                 app_key: 'S3AppKey',
                                 app_secret: 'S3AppSecret',
                                 bucket: 's3.bucket',
                                 region: 'us-east-1'
                               })
  end

  def unstub_configuration
    BrowseEverything.configure(nil)
  end
end
