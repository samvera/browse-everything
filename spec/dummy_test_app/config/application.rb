require_relative 'boot'

require 'rails/all'

Bundler.require(*Rails.groups)
require "browse_everything"

# Since we don't actually have an app-specific Gemfile,
# Some development dependencies listed in .gemspec need to be required here,
# that would ordinarily be auto-required by being in a Gemfile instead of gemspec.
require 'bootstrap'
require 'sprockets/railtie'
require 'jquery-rails'
require 'turbolinks'

module Dummy
  class Application < Rails::Application
    # ~Initialize configuration defaults for originally generated Rails version.~
    # Changed to: For currently running Rails version, eg 5.2 or 7.0:
    config.load_defaults Rails::VERSION::STRING.to_f

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.
  end
end

