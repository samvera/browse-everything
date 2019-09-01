
class Session < JSONAPI::Resource
  has_one :provider
  has_one :root_container
end
