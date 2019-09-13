# frozen_string_literal: true

require 'rails/generators'

class BrowseEverything::InstallGenerator < Rails::Generators::Base
  desc 'This generator installs the browse everything configuration into your application'

  source_root File.expand_path('templates', __dir__)

  def inject_config
    generate 'browse_everything:config'
  end

  def copy_migrations
    rake "browse_everything:install:migrations"
  end

  # This should be removed with --skip-turbolinks, and that is passed in
  # .engine_cart.yml
  def remove_turbolinks
    gsub_file('Gemfile', /gem 'turbolinks'.*$/, '')
    # This is specific to Rails 5.2.x releases
    gsub_file('app/assets/javascripts/application.js', /\/\/= require turbolinks.*$/, '')
  end
end
