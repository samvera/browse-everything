module BrowseEverything
  module Driver
    class Kaltura < Base
      require 'kaltura'      

      def icon
        'kaltura'
      end

      def validate_config
        unless [:partner_id,:administrator_secret,:service_url].all? { |key| config[key].present? }
          raise BrowseEverything::InitializationError, "Kaltura driver requires :partner_id, :administrator_secret, and :service_url"
        end
      end

      def contents(path='')
        result = []
        $current_user = main_app.scope.env['warden'].user.email.split("@")[0]
        @options = { :filter => { :creatorIdEqual => $current_user } }
        @session = ::Kaltura::Session.start
        @@entries = ::Kaltura::MediaEntry.list(@options)
        @@entries.each do |item|
          item.location = item.downloadUrl.sub('https:', 'kaltura:')
          item.mtime = Time.at(item.updatedAt.to_i)
          result.push(item) 
        end
        result
      end

      def link_for(path)
        correct_path = path.sub('//', 'https://')
        file_list = @@entries
        extras = {file_name: ''}
        file_list.each do |file|
          if file.downloadUrl == correct_path
            extras[:file_name] = file.name
          end
        end
        ret = [correct_path, extras]
      end

      def details(path)
        byebug
        contents(path).first
      end

      def authorized?
        true
      end
    
    end
  end
end
