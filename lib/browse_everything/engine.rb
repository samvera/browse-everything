# frozen_string_literal: true

module BrowseEverything
  class Engine < ::Rails::Engine
    Mime::Type.register 'application/vnd.api+json', :json_api
  end
end
