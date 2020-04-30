# frozen_string_literal: true

module BrowseEverything
  class Upload
    attr_accessor :uuid, :bytestreams, :bytestream_ids, :file_ids, :processed
    attr_writer :session, :session_id, :containers, :container_ids
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

    def find_child_containers(container, cache)
      values = []
      return values if container.container_ids.empty?

      container.container_ids.each do |child_id|
        unless cache.key?(child_id)
          child = driver.find_container(id: child_id)
          values << child
        end
      end

      nested_children = values.map { |child| find_child_containers(child, cache) }
      values + nested_children.flatten
    end

    def containers
      return @cached_containers unless @cached_containers.nil?

      values = []
      cached = {}

      @containers.each do |container|
        cached[container.id] = container
      end

      @container_ids.each do |container_id|
        unless cached.key?(container_id)
          container = driver.find_container(id: container_id)
          cached[container_id] = container
        end
      end

      cached.values.each do |container|
        values << container
        values += find_child_containers(container, cached)
      end

      values.sort! { |u, v| (u.name <=> v.name) + (u.id.length <=> v.id.length) }

      @cached_containers = values
    end

    def container_ids
      @cached_container_ids ||= @container_ids = containers.map(&:id)
    end

    def initialize(processed: false)
      @processed = processed
    end

    # For Upload Objects to be serializable, they must have a zero-argument constructor
    # @param session_id
    # @return [Session]
    def self.build(id: SecureRandom.uuid,
                   processed: false,
                   session_id: nil, session: nil,
                   bytestream_ids: [], bytestreams: [],
                   container_ids: [], containers: [],
                   file_ids: [])
      browse_everything_upload = Upload.new
      browse_everything_upload.uuid = id
      browse_everything_upload.processed = processed
      browse_everything_upload.session = session
      browse_everything_upload.session_id = if session.nil?
                                              session_id
                                            else
                                              session
                                            end

      browse_everything_upload.bytestreams = bytestreams
      browse_everything_upload.bytestream_ids = if bytestreams.empty?
                                                  bytestream_ids
                                                else
                                                  bytestreams.map(&:id)
                                                end

      browse_everything_upload.containers = containers
      browse_everything_upload.container_ids = if containers.empty?
                                                 container_ids
                                               else
                                                 containers.map(&:id)
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

      def all
        upload_models = orm_class.all
        models = upload_models
        models.map do |model|
          new_attributes = JSON.parse(model.upload)
          build(**new_attributes.symbolize_keys)
        end
      end
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
        'file_ids' => file_ids,
        'processed' => processed
      }
    end

    # Build the JSON-API serializer Object
    # @return [SessionSerializer]
    def serializer
      @serializer ||= self.class.serializer_class.new(self)
    end

    alias id uuid
    delegate :save, :save!, :destroy, :destroy!, to: :orm # Persistence methods
    # @todo There needs to be a callback here if #destroy and #destroy! remove downloaded files

    # Sessions are responsible for managing the relationships to authorizations
    delegate :authorizations, :auth_code, to: :session

    def perform_job
      job.perform(upload_id: id)
    end

    # These are the ActiveStorage files retrieved from the server and saved on
    # disk to a temporary location
    def files
      file_ids.map do |file_id|
        UploadFile.find(file_id)
      end
    end

    def session_id
      @cached_sesson_id ||= @session_id = session.id
    end

    def session
      return if @session_id.blank?

      @cached_session ||= begin
                            sessions = BrowseEverything::Session.find_by(uuid: @session_id)
                            @session = sessions.first
                          end
    end
    delegate :driver, :provider, to: :session

    private

      # Create a new ActiveJob object for supporting asynchronous uploads
      # Maybe what could be done is that there is an UploadedFile Model with
      # ActiveStorage which is retrieved?
      # If that is the preferred approach, blocking until the ActiveJob completes
      # needs to be supported...
      def job
        self.class.job_class.new(**default_job_args)
      end

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
        else
          orm_model = existing_orm.first
          orm_model.upload = json_attributes
        end
        orm_model.save
        @orm = orm_model.reload
      end

      def default_job_args
        {
          upload_id: id.to_s
        }
      end
  end
end
