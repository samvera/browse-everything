# frozen_string_literal: true

require 'rails/generators'

class BrowseEverything::ConfigGenerator < Rails::Generators::Base
  desc <<-DESC
  This generator makes the following changes to your application:
   1. Creates config/browse_everything_providers.yml with a placeholder value
   2. Modifies your app's routes.rb to mount BrowseEverything at /browse
    DESC
  source_root File.expand_path('templates', __dir__)

  def inject_routes
    insert_into_file 'config/routes.rb', after: '.draw do' do
      %(
        mount BrowseEverything::Engine => '/browse')
    end
  end

  def copy_example_config
    FileUtils.rm 'config/browse_everything_providers.yml', force: true if File.exists? 'config/browse_everything_providers.yml'
    copy_file 'browse_everything_providers.yml.example', 'config/browse_everything_providers.yml', force: true
  end

  def insert_file_system_path
    insert_into_file 'config/browse_everything_providers.yml', before: '# dropbox:' do
      "file_system:\n  home: #{Rails.root}\n"
    end
  end
end
