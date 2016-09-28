# -*- encoding : utf-8 -*-
require 'rails/generators'

class BrowseEverything::AssetsGenerator < Rails::Generators::Base
  desc 'This generator installs the browse_everything CSS assets into your application'

  source_root File.expand_path('../templates', __FILE__)

  def inject_css
    copy_file 'browse_everything.scss', 'app/assets/stylesheets/browse_everything.scss'
  end
end
