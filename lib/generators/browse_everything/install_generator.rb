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

  def install_webpacker
    rake "webpacker:install"
  end

  # This should be removed with --skip-turbolinks, and that is passed in
  # .engine_cart.yml
  def remove_turbolinks
    gsub_file('Gemfile', /gem 'turbolinks'.*$/, '')
    # This is specific to Rails 5.2.z releases
    if Rails.version =~ /^5\./
      gsub_file('app/assets/javascripts/application.js', /\/\/= require turbolinks.*$/, '')
    elsif File.exists?(Rails.root.join('app', 'assets', 'javascripts', 'application.js'))
      # This is specific to Rails 6.y.z releases
      gsub_file('app/assets/javascripts/application.js', /require\("turbolinks".*$/, '')
    end
  end

  def install_active_storage
    rake "active_storage:install"
  end

  def install_rswag
    # This is needed for a bug, as rswag will not install for the dependent app.
    # unless it is explicitly required here
    insert_into_file 'config/application.rb', after: 'require "rails/test_unit/railtie"' do
      "\nrequire 'rswag'"
    end

    generate 'rswag:install'
  end
end
