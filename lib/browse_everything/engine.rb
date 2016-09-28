module BrowseEverything
  class Engine < ::Rails::Engine
    config.assets.paths << config.root.join('vendor', 'assets', 'javascripts')
    config.assets.paths << config.root.join('vendor', 'assets', 'stylesheets')
    config.assets.precompile += %w(browse_everything.js)
    config.assets.precompile += %w(browse_everything.css)
  end
end
