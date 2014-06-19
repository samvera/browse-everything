module BrowseEverything
  class Engine < ::Rails::Engine
    initializer :assets do |config|
      Rails.application.config.assets.precompile += %w{ browse_everything.js }
      Rails.application.config.assets.precompile += %w{ browse_everything.css }
    end
  end
end