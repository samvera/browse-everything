# frozen_string_literal: true
module BrowseEverything
  class Session
    attr_accessor :uuid, :provider_id, :host, :port, :authorization_ids
    include ActiveModel::Serialization

    # Define the ORM persister Class
    # @return [Class]
    def self.orm_class
      SessionModel
    end

    # Define the JSON-API persister Class
    # @return [Class]
    def self.serializer_class
      SessionSerializer
    end

    # For Session Objects to be serializable, they must have a zero-argument constructor
    # @param provider_id
    # @param authorization_ids
    # @param session
    # @param host
    # @param port
    # @return [Session]
    def self.build(provider_id: nil, authorization_ids: [], host: nil,
                   port: nil, id: SecureRandom.uuid)
      browse_everything_session = Session.new
      browse_everything_session.uuid = id
      browse_everything_session.provider_id = provider_id
      browse_everything_session.authorization_ids = authorization_ids
      browse_everything_session.host = host
      browse_everything_session.port = port
      browse_everything_session
    end

    class << self
      # Query service methods
      #
      # @see ActiveRecord::Base.find_by
      # @return [Array<Session>]
      def where(**arguments)
        session_models = orm_class.where(**arguments)
        models = session_models
        models.map do |model|
          new_attributes = JSON.parse(model.session)
          build(**new_attributes.symbolize_keys)
        end
      end
      alias find_by where
    end

    # Generate the attributes used for serialization
    # @see ActiveModel::Serialization
    # @return [Hash]
    def attributes
      {
        'id' => uuid,
        'provider_id' => provider_id,
        'host' => host,
        'port' => port,
        'authorization_ids' => authorization_ids
      }
    end

    # Build the JSON-API serializer Object
    # @return [SessionSerializer]
    def serializer
      @serialize ||= self.class.serializer_class.new(self)
    end

    alias id uuid
    # Persistence methods
    delegate :save, :save!, :destroy, :destroy!, to: :orm

    def authorizations
      values = authorization_ids.map do |authorization_id|
        # This needs to be restructured to something like
        # query_service.find_by(id: authorization_id) (to support Valkyrie)
        results = Authorization.find_by(uuid: authorization_id)
        results.first
      end

      values.compact
    end

    def auth_code
      return if authorizations.empty?

      # Retrieve the most recent authorization
      authorizations.last.code
    end

    def driver
      @driver ||= Driver.build(id: provider_id, auth_code: auth_code, host: host, port: port)
    end

    delegate :root_container, to: :driver
    delegate :authorization_url, to: :driver

    private

      # There should be a BrowseEverything.metadata_adapter layer here for
      # providing closer Valkyrie integration
      def orm
        return @orm unless @orm.nil?

        # This ensures that the ID is persisted
        json_attributes = JSON.generate(attributes)

        # Search for the model by UUID first
        existing_orm = self.class.orm_class.where(uuid: uuid)
        if existing_orm.empty?
          orm_model = self.class.orm_class.new(uuid: uuid, session: json_attributes)
        else
          orm_model = existing_orm.first
          orm_model.session = json_attributes
        end
        orm_model.save
        @orm = orm_model.reload
      end
  end
end
