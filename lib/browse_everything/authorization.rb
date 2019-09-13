# frozen_string_literal: true
module BrowseEverything
  class Authorization
    attr_accessor :code
    include ActiveModel::Serialization

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
    def self.build(code: nil)
      authorization = Authorization.new
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
        authorization_models.map(&:authorization)
      end
      alias find_by where
    end

    # Generate the attributes used for serialization
    # @see ActiveModel::Serialization
    # @return [Hash]
    def attributes
      {
        'id' => id,
        'code' => code
      }
    end

    # Build the JSON-API serializer Object
    # @return [AuthorizationSerializer]
    def serializer
      @serialize ||= self.class.serializer_class.new(self)
    end

    def id
      return if @orm.nil?
      @orm.id
    end
    delegate :save, :save!, :destroy, :destroy!, to: :orm # Persistence methods

    private

      #  There should be a BrowseEverything.metadata_adapter layer here for
      # providing closer Valkyrie integration
      def orm
        return @orm unless @orm.nil?

        # This ensures that the ID is persisted
        orm_model = self.class.orm_class.new(authorization: self)
        orm_model.save
        @orm = orm_model.reload
      end
  end
end
