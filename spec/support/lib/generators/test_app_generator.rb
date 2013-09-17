require 'rails/generators'

class TestAppGenerator < Rails::Generators::Base
  source_root File.expand_path("../../../../internal", __FILE__)
  def inject_css
    copy_file "app/assets/stylesheets/application.css", "app/assets/stylesheets/application.css.scss"
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

  def update_gemfile
    append_file "Gemfile" do
      "gem 'bootstrap-sass'\ngem 'font-awesome-rails'"
    end
  end

  def inject_routes
    insert_into_file "config/routes.rb", :after => ".draw do" do
      "\n\nmount BrowseEverything::Engine => '/browse'\n\n"
    end
  end

  def create_bev_configuration
    create_file "config/browse_everything_providers.yml" do
      YAML.dump({ 'file_system' => { :home => Rails.root.to_s }})
    end
  end
end