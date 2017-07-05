require 'rails/generators'

class TestAppGenerator < Rails::Generators::Base
  source_root File.expand_path('../../../../spec/support', __FILE__)

  def run_config_generator
    generate 'browse_everything:config'
  end

  def inject_css
    copy_file File.expand_path('app/assets/stylesheets/application.css', ENV['RAILS_ROOT']), 'app/assets/stylesheets/application.css.scss'
    remove_file 'app/assets/stylesheets/application.css'
    insert_into_file 'app/assets/stylesheets/application.css.scss', after: '*/' do
      %(\n\n@import "browse_everything")
    end
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
        get '/main', :to => "file_handler#main"
        post '/file', :to => "file_handler#update"
      )
    end
  end

  def create_test_route
    copy_file 'app/controllers/file_handler_controller.rb', 'app/controllers/file_handler_controller.rb'
    copy_file 'app/views/file_handler/main.html.erb', 'app/views/file_handler/main.html.erb'
    copy_file 'app/views/file_handler/index.html.erb', 'app/views/file_handler/index.html.erb'
  end
end
