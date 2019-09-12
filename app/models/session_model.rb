class SessionModel < ApplicationRecord
  serialize :session, BrowseEverything::Session
end
