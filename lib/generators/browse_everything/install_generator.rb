# -*- encoding : utf-8 -*-
require 'rails/generators'

class BrowseEverything::InstallGenerator < Rails::Generators::Base
  class_option :'skip-assets', type: :boolean, default: false, desc: 'Skip generating javascript and css assets into the application'

  desc 'This generator installs the browse everything configuration and assets into your application'

  source_root File.expand_path('../templates', __FILE__)

  def inject_config
    generate 'browse_everything:config'
  end

  def inject_assets
    generate 'browse_everything:assets' unless options[:'skip-assets']
  end
end
