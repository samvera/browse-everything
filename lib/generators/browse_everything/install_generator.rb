# frozen_string_literal: true

require 'rails/generators'
require 'fileutils'

class BrowseEverything::InstallGenerator < Rails::Generators::Base
  desc 'This generator installs the browse everything configuration into your application'

  source_root File.expand_path('templates', __dir__)

  def inject_config
    generate 'browse_everything:config'
  end

  def install_webpacker
    rake 'webpacker:install'
  end

  def copy_migrations
    rake 'browse_everything_engine:install:migrations'
  end

  # This should be removed with --skip-turbolinks, and that is passed in
  # .engine_cart.yml
  def remove_turbolinks
    gsub_file('Gemfile', /gem 'turbolinks'.*$/, '')
    # This is specific to Rails 5.2.z releases
    if Rails.version =~ /^5\./
      gsub_file('app/assets/javascripts/application.js', %r{//= require turbolinks.*$}, '')
    elsif File.exist?(Rails.root.join('app', 'assets', 'javascripts', 'application.js'))
      # This is specific to Rails 6.y.z releases
      gsub_file('app/assets/javascripts/application.js', /require\("turbolinks".*$/, '')
    end
  end

  def install_active_storage
    rake 'active_storage:install'
  end

  def install_rack_cors
    application <<-RUBY
        config.middleware.insert_before 0, Rack::Cors do
          allow do
            origins '*'
            resource '*', headers: :any, methods: [:get, :post, :options]
          end
        end
    RUBY
  end

  # Things get more complicated here with RSpec
  # Need to install rspec, rspec-rails
  def install_rspec
    run 'rspec --init'
    insert_into_file 'spec/spec_helper.rb', before: 'RSpec.configure do |config|' do
      "\nrequire 'rails'\nrequire 'rspec'\nrequire 'rspec-rails'\n"
    end
  end

  def install_rswag
    # This is needed for a bug, as rswag will not install for the dependent app.
    # unless it is explicitly required here
    insert_into_file 'config/application.rb', after: 'require "rails/test_unit/railtie"' do
      "\nrequire 'rswag'"
    end

    generate 'rswag:install'
    gsub_file 'spec/swagger_helper.rb',
              "  config.swagger_root = Rails.root.join('swagger').to_s",
              "rails_root_path = Pathname.new(File.dirname(__FILE__))\nconfig.swagger_root = rails_root_path.join('..', 'swagger').to_s"
    gsub_file 'spec/swagger_helper.rb',
              "require 'rails_helper'",
              "require 'spec_helper'"

    insert_into_file 'spec/spec_helper.rb', after: 'require \'rspec/rails\'' do
      "\nrequire 'rswag'"
    end
  end

  def install_swagger_api_spec
    FileUtils.mkdir_p Rails.root.join('swagger', 'v1')
    copy_file 'swagger/v1/swagger.json', 'swagger/v1/swagger.json'
  end

  def install_swagger_tests
    FileUtils.mkdir_p Rails.root.join('spec', 'integration')
    pattern = Rails.root.join('..', 'spec', 'integration', '*_spec.rb').to_s
    Dir.glob(pattern).each do |test_file_path|
      basename = File.basename(test_file_path)
      target_path = Rails.root.join('spec', 'integration', basename)
      copy_file test_file_path, target_path
    end
  end
end
