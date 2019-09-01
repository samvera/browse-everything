module BrowseEverything
  class Upload
    class_attribute :job_class

    self.job_class = UploadJob # This might by overridden for Hyrax or Valkyrie applications
    attr_accessor :id, :session_id, :bytestream_ids, :container_ids

    # Constructor
    # @param id
    # @param session_id
    # @param bytestream_ids
    # @param container_ids
    def initialize(id: SecureRandom.uuid, session_id:, bytestream_ids: [], container_ids: [])
      @id = id
      @session_id = session_id
      @bytestream_ids = bytestream_ids
      @container_ids = container_ids
    end

    def job
      self.class.job_class.new(**job_args)
    end

    private

      def job_args
        {
          upload_id: self.id.to_s
        }
      end
  end
end
