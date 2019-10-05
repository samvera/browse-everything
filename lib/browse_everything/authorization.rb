# frozen_string_literal: true
module BrowseEverything
  class Authorization
    include ActiveModel::Serialization
    attr_accessor :uuid, :code

    # Define the ORM persister Class
    # @return [Class]
    def self.orm_class
      AuthorizationModel
    end

    # Define the JSON-API persister Class
    # @return [Class]
    def self.serializer_class
      AuthorizationSerializer
    end

    # For Session Objects to be serializable, they must have a 0-argument
    # constructor
    def self.build(code: nil, id: SecureRandom.uuid)
      authorization = Authorization.new
      authorization.uuid = id
      authorization.code = code
      authorization
    end

    class << self
      # Query service methods
      #
      # @see ActiveRecord::Base.where
      # @return [Array<Authorization>]
      def where(**arguments)
        authorization_models = orm_class.where(**arguments)
        models = authorization_models
        models.map do |model|
          new_attributes = JSON.parse(model.authorization)
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
        'code' => code
      }
    end

    # Build the JSON-API serializer Object
    # @return [AuthorizationSerializer]
    def serializer
      @serialize ||= self.class.serializer_class.new(self)
    end

    alias :id :uuid
    # Persistence methods for the ActiveRecord ORM
    delegate :save, :save!, :destroy, :destroy!, to: :orm

    private

      #  There should be a BrowseEverything.metadata_adapter layer here for
      # providing closer Valkyrie integration
      def orm
        return @orm unless @orm.nil?

        # This ensures that the ID is persisted
        json_attributes = JSON.generate(attributes)

        # Search for the model by UUID first
        existing_orm = self.class.orm_class.where(uuid: uuid)
        if existing_orm.empty?
          orm_model = self.class.orm_class.new(uuid: uuid, authorization: json_attributes)
          orm_model.save
        else
          orm_model = existing_orm.first
          orm_model.authorization = json_attributes
          orm_model.save
        end
        @orm = orm_model.reload
      end
  end
end
