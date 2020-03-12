# frozen_string_literal: true

module BrowseEverything
  class ProviderSerializer
    include FastJsonapi::ObjectSerializer
    attributes :id, :name

    # rubocop:disable Style/SymbolProc
    link :authorization_url do |object|
      object.authorization_url
    end
    # rubocop:enable Style/SymbolProc
  end
end
