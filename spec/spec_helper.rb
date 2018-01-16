require 'engine_cart'
require File.expand_path('config/environment', EngineCart.destination)
require 'rspec'
require 'rspec/rails'
require 'rspec/its'
require 'webmock/rspec'
require 'simplecov'
require 'vcr'
require 'capybara/rails'
require 'capybara/rspec'
require 'coveralls'
# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[Pathname.new(File.expand_path('../support/**/*.rb', __FILE__))].each { |f| require f }

Coveralls.wear!
EngineCart.load_application!

SimpleCov.start do
  add_filter '/spec/'
end

VCR.configure do |c|
  c.cassette_library_dir = 'spec/fixtures/vcr_cassettes'
  c.hook_into :webmock
  c.configure_rspec_metadata!
  c.ignore_localhost = true
end

RSpec.configure do |config|
  config.expect_with :rspec do |c|
    c.syntax = [:should, :expect]
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
                                 home: File.expand_path('../fixtures/file_system', __FILE__)
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
                                 bucket: 's3.bucket'
                               })
  end

  def unstub_configuration
    BrowseEverything.configure(nil)
  end
end
