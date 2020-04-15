# frozen_string_literal: true

require 'rails/generators'

class BrowseEverything::InstallGenerator < Rails::Generators::Base
  desc 'This generator installs the browse everything configuration into your application'

  source_root File.expand_path('templates', __dir__)

  def inject_config
    generate 'browse_everything:config'
  end

  # While there's no reason browse-everything can't work with a properly configured
  # sprockets 4 (including configured to deal with Javascript), our install generator
  # isn't capable of setting this up right now, so instead we'll inject into the app
  # a sprockets 3 requirement...
  def sprockets_3_restriction
    gem 'sprockets', '~> 3.7'
  end
end
