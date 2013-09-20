require 'rails/generators'

class TestAppGenerator < Rails::Generators::Base
  source_root File.expand_path("../../../../support", __FILE__)
  def inject_css
    copy_file "../internal/app/assets/stylesheets/application.css", "app/assets/stylesheets/application.css.scss"
    remove_file "app/assets/stylesheets/application.css"
    insert_into_file "app/assets/stylesheets/application.css.scss", :after => '*/' do
      %{\n\n@import "browse_everything"}
    end
  end

  def inject_javascript
    insert_into_file "app/assets/javascripts/application.js", :after => '//= require_tree .' do
      "\n//= require browse_everything"
    end
  end

  def inject_application
    insert_into_file "config/application.rb", :after => 'Rails::Application' do
      "\nconfig.autoload_paths+=[File.join(Rails.root,'../../lib')]"
    end
  end

  def update_gemfile
    append_file "Gemfile" do
      "gem 'bootstrap-sass'\ngem 'font-awesome-rails'"
    end
  end

  def inject_routes
    insert_into_file "config/routes.rb", :after => ".draw do" do
      %{

  mount BrowseEverything::Engine => '/browse'
  root :to => "file_handler#index"
  post '/file', :to => "file_handler#update", :as => "browse_everything_file_handler"
      }
    end
  end

  def create_bev_configuration
    create_file "config/browse_everything_providers.yml" do
      YAML.dump({ 'file_system' => { :home => Rails.root.to_s }})
    end
  end

  def create_test_route
    copy_file "app/controllers/file_handler_controller.rb", "app/controllers/file_handler_controller.rb"
    copy_file "app/views/file_handler/index.html.erb", "app/views/file_handler/index.html.erb"
  end

  def copy_example_config
    copy_file "config/browse_everything_providers.yml.example", "config/browse_everything_providers.yml.example"
  end
end
