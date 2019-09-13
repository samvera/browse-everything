# frozen_string_literal: true
class AuthorizationModel < ApplicationRecord
  serialize :authorization, BrowseEverything::Authorization
end
