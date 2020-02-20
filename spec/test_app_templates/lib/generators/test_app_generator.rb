# frozen_string_literal: true

require 'rails/generators'

class TestAppGenerator < Rails::Generators::Base
  source_root File.expand_path('../../../spec/test_app_templates', __dir__)

  def install_engine
    generate 'browse_everything:install -f'
  end

  def run_config_generator
    generate 'browse_everything:config'
  end

  def inject_javascript
    insert_into_file 'app/assets/javascripts/application.js', after: '//= require_tree .' do
      %(
        //= require jquery
        //= require browse_everything
      )
    end
  end

  def inject_application
    insert_into_file 'config/application.rb', after: 'Rails::Application' do
      "\nconfig.autoload_paths+=[File.join(Rails.root,'../../lib')]"
    end
  end

  def inject_routes
    insert_into_file 'config/routes.rb', after: '.draw do' do
      %(

        root :to => "file_handler#index"
      )
    end
  end

  def create_test_route
    copy_file '../support/app/controllers/file_handler_controller.rb', 'app/controllers/file_handler_controller.rb'
    copy_file '../support/app/views/file_handler/index.html.erb', 'app/views/file_handler/index.html.erb'
  end
end
