# -*- encoding : utf-8 -*-
require 'rails/generators'

class BrowseEverything::ConfigGenerator < Rails::Generators::Base
    desc """
  This generator makes the following changes to your application:
   1. Creates config/browse_everything_providers.yml with a placeholder value
   2. Creates config/browse_everything_providers.yml.example with examples of how to configure more providers
   3. Modifies your app's routes.rb to mount BrowseEverything at /browse
         """
  source_root File.expand_path('../templates', __FILE__)
   
  def inject_routes
   insert_into_file "config/routes.rb", :after => ".draw do" do
%{
  mount BrowseEverything::Engine => '/browse'}
   end
  end 
  
  def create_bev_configuration
    create_file "config/browse_everything_providers.yml" do
      YAML.dump({ 'file_system' => { :home => Rails.root.to_s }})
    end
  end
  
  def copy_example_config
    copy_file "browse_everything_providers.yml.example", "config/browse_everything_providers.yml.example"
  end
        
end