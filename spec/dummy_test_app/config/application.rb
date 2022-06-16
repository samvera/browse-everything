require_relative 'boot'

require 'rails/all'

Bundler.require(*Rails.groups)
require "browse_everything"

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

