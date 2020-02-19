# frozen_string_literal: true

class AuthorizationSerializer
  include FastJsonapi::ObjectSerializer
  attributes :id, :code
end
