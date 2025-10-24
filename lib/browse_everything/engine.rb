# frozen_string_literal: true

module BrowseEverything
  class Engine < ::Rails::Engine
    # As of Rails 7, sprockets is optional in Rails. If you don't have sprockets-rails
    # installed, you don't have a config.assets.  Without sprockets, you may
    # or may not be able to figure out how to get browse-everything JS and CSS to load,
    # but we should at least let you load the engine and try, so we don't try
    # to configure sprockets unless it is installed...

    initializer 'browse_everything.assets.precompile' do |app|
      if app.config.respond_to?(:assets)
        app.config.assets.paths << root.join('node_modules').to_s
        # Add Bootstrap Icons fonts directory to asset paths so font-url() can find them
        app.config.assets.paths << root.join('node_modules', 'bootstrap-icons', 'font', 'fonts').to_s
        app.config.assets.precompile += %w[browse_everything.js browse_everything.scss]
      end
    end
  end
end
