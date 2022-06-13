# frozen_string_literal: true

module BrowseEverything
  class Engine < ::Rails::Engine
    # As of Rails 7, sprockets is optional in Rails. If you don't have sprockets-rails
    # installed, you don't have a config.assets.  Without sprockets, you may
    # or may not be able to figure out how to get browse-everything JS and CSS to load,
    # but we should at least let you load the engine and try, so we don't try
    # to configure sprockets unless it is installed...
    if config.respond_to?(:assets)
      config.assets.paths << config.root.join('vendor', 'assets', 'javascripts')
      config.assets.paths << config.root.join('vendor', 'assets', 'stylesheets')
      config.assets.precompile += %w[browse_everything.js browse_everything.css]
    end
  end
end
