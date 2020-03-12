# frozen_string_literal: true

module BrowseEverything
  class AuthorizationSerializer
    include FastJsonapi::ObjectSerializer
    attributes :id, :code
  end
end
