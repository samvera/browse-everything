class AuthorizationSerializer
  include FastJsonapi::ObjectSerializer
  attributes :id, :code
end
