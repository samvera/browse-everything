# frozen_string_literal: true
module BrowseEverything
  class Upload
    attr_accessor :uuid, :session, :session_id, :bytestreams, :bytestream_ids, :containers, :container_ids, :file_ids
    include ActiveModel::Serialization

    # Define the ORM persister Class
    # @return [Class]
    def self.orm_class
      UploadModel
    end

    # Define the JSON-API persister Class
    # @return [Class]
    def self.serializer_class
      UploadSerializer
    end

    def self.job_class
      UploadJob
    end

    # For Upload Objects to be serializable, they must have a zero-argument constructor
    # @param session_id
    # @return [Session]
    def self.build(session_id: nil, session: nil, bytestream_ids: [],
                   bytestreams: [], container_ids: [], containers: [],
                   file_ids: [], id: SecureRandom.uuid)
      browse_everything_upload = Upload.new
      browse_everything_upload.uuid = id
      browse_everything_upload.session = session
      browse_everything_upload.session_id = if session.nil?
                                              session_id
                                            else
                                              session
                                            end

      browse_everything_upload.bytestreams = bytestreams
      if bytestreams.empty?
        browse_everything_upload.bytestream_ids = bytestream_ids
      else
        browse_everything_upload.bytestream_ids = bytestreams.map(&:id)
      end

      browse_everything_upload.containers = containers
      if containers.empty?
        browse_everything_upload.container_ids = container_ids
      else
        browse_everything_upload.container_ids = containers.map(&:id)
      end

      browse_everything_upload.file_ids = file_ids

      browse_everything_upload
    end

    class << self
      # Query service methods
      #
      # @see ActiveRecord::Base.find_by
      # @return [Array<Session>]
      def where(**arguments)
        upload_models = orm_class.where(**arguments)
        models = upload_models
        models.map do |model|
          new_attributes = JSON.parse(model.upload)
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
        'session_id' => session_id,
        'bytestream_ids' => bytestream_ids,
        'container_ids' => container_ids,
        'file_ids' => file_ids
      }
    end

    # Build the JSON-API serializer Object
    # @return [SessionSerializer]
    def serializer
      @serialize ||= self.class.serializer_class.new(self)
    end

    alias :id :uuid
    delegate :save, :save!, :destroy, :destroy!, to: :orm # Persistence methods

    # Sessions are responsible for managing the relationships to authorizations
    delegate :authorizations, :auth_code, to: :session

    # Create a new ActiveJob object for supporting asynchronous uploads
    # Maybe what could be done is that there is an UploadedFile Model with
    # ActiveStorage which is retrieved?
    # If that is the preferred approach, blocking until the ActiveJob completes
    # needs to be supported...
    def job
      self.class.job_class.new(**default_job_args)
    end

    # These are the ActiveStorage files retrieved from the server and saved on
    # disk to a temporary location
    def files
      file_ids.map do |file_id|
        UploadFile.find(file_id)
      end
    end

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
          orm_model = self.class.orm_class.new(uuid: uuid, upload: json_attributes)
          orm_model.save
        else
          orm_model = existing_orm.first
          orm_model.upload = json_attributes
          orm_model.save
        end
        @orm = orm_model.reload
      end

      def default_job_args
        {
          upload_id: id.to_s
        }
      end
  end
end
