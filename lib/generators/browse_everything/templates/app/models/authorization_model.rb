class AuthorizationModel < ApplicationRecord
  serialize :authorization, BrowseEverything::Authorization
end
