# frozen_string_literal: true
class SessionModel < ApplicationRecord
  serialize :session, BrowseEverything::Session
end
