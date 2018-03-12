# frozen_string_literal: true

# Object for handling session cookies containing cached values
class BrowseEverythingSession
  class ProviderSession < Base
    class_attribute :sessions
    self.sessions = {}

    def self.for(session:, name:)
      return sessions[name] if sessions[name]
      sessions[name] = ProviderSession.new(session: session, name: name)
    end

    def initialize(session:, name:)
      @name = name
      super(session: session)
    end

    def token=(value)
      @session["#{@name}_token"] = value
    end

    def token
      @session["#{@name}_token"]
    end

    def code=(value)
      @session["#{@name}_code"] = value
    end

    def code
      @session["#{@name}_code"]
    end

    def data=(value)
      @session["#{@name}_data"] = value
    end

    def data
      @session["#{@name}_data"]
    end
  end
end
