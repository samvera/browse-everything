module BrowseEverything
  class Engine < ::Rails::Engine
    initializer :assets do |config|
      config.assets.paths << config.root.join('vendor', 'assets', 'javascripts')
      config.assets.paths << config.root.join('vendor', 'assets', 'stylesheets')
      Rails.application.config.assets.precompile += %w{ browse_everything.js }
      Rails.application.config.assets.precompile += %w{ browse_everything.css }
    end
  end
end
