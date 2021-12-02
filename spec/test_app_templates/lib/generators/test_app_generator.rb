# frozen_string_literal: true

require 'rails/generators'

require 'pry-byebug'

class TestAppGenerator < Rails::Generators::Base
  source_root File.expand_path('../../../spec/test_app_templates', __dir__)

  def install_engine
    generate 'browse_everything:install -f'
  end

  def run_config_generator
    generate 'browse_everything:config'
  end

  def inject_css
    copy_file File.expand_path('app/assets/stylesheets/application.css', ENV['RAILS_ROOT']), 'app/assets/stylesheets/application.css.scss'
    remove_file 'app/assets/stylesheets/application.css'
    insert_into_file 'app/assets/stylesheets/application.css.scss', after: '*/' do
      if ENV['TEST_BOOTSTRAP'] == "3"
        # bootstrap 3 from bootstrap-sass gem
        %(\n\n@import "bootstrap-sprockets";\n@import "bootstrap";\n@import "browse_everything/browse_everything_bootstrap3";)
      else
        # bootstrap4 from bootstrap gem
        %(\n\n@import "bootstrap";\n@import "browse_everything/browse_everything_bootstrap4";)
      end
    end
  end

  def inject_javascript
    if /^6\./.match?(Rails.version)
      # Both jQuery and Twitter Bootstrap 3.x need to be added for legacy JavaScript
      system('yarn add jquery@3.3.1')
      system('yarn add bootstrap@3.4.1')
      system('yarn install')

      # Adding the JavaScript module dependencies
      insert_into_file 'app/javascript/packs/application.js', after: 'require("channels")' do
        %(
          require("jquery")
          require("bootstrap")
        )
      end

      # Here the JavaScript needs to be injected for Webpacker
      insert_into_file 'config/webpack/environment.js', after: "const { environment } = require('@rails/webpacker')" do
        %(
          const webpack = require('webpack')

          environment.plugins.prepend('Provide',
            new webpack.ProvidePlugin({
              $: 'jquery/src/jquery',
              jQuery: 'jquery/src/jquery'
            })
          )
        )
      end

      # Copy the TreeTable JavaScript
      copy_file('../../app/assets/javascripts/treetable.webpack.js', 'app/javascript/packs/treetable.js')

      # Copy the browse_everything JavaScript
      copy_file('../../app/assets/javascripts/browse_everything/behavior.js', 'app/javascript/packs/browse-everything.js')

      # Adding the JavaScript module dependencies
      insert_into_file 'app/javascript/packs/browse-everything.js', before: "'use strict';" do
        %(
          require("bootstrap")
          require("./treetable")
        )
      end

      # Load the new packs into the view
      insert_into_file 'app/views/layouts/application.html.erb', before: '</head>' do
        %(
          <%= javascript_pack_tag 'treetable', 'data-turbolinks-track': 'reload' %>
          <%= javascript_pack_tag 'browse-everything', 'data-turbolinks-track': 'reload' %>
        )
      end
    else
      insert_into_file 'app/assets/javascripts/application.js', after: '//= require_tree .' do
        %(
          //= require jquery
          //= require browse_everything
        )
      end
    end
  end

  def inject_application
    # binding.pry

    insert_into_file 'config/application.rb', after: 'Rails::Application' do
      "\nconfig.autoload_paths+=[File.join(Rails.root,'../../lib')]"
    end
  end

  def inject_routes
    # binding.pry

    insert_into_file 'config/routes.rb', after: '.draw do' do
      %(
        root :to => "file_handler#index"
        get '/main', :to => "file_handler#main"
        post '/file', :to => "file_handler#update"
      )
    end
  end

  def create_test_route
    # binding.pry

    copy_file '../support/app/controllers/file_handler_controller.rb', 'app/controllers/file_handler_controller.rb'
    copy_file '../support/app/views/file_handler/main.html.erb', 'app/views/file_handler/main.html.erb'
    copy_file '../support/app/views/file_handler/index.html.erb', 'app/views/file_handler/index.html.erb'
  end
end
