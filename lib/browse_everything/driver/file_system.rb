module BrowseEverything
  module Driver
    class FileSystem < Base

      def icon
        'file'
      end
      
      def validate_config
        unless config[:home]
          raise BrowseEverything::InitializationError, "FileSystem driver requires a :home argument"
        end
      end

      def contents(path='')
        relative_path = path.sub(%r{^[\/.]+},'')
        real_path = File.join(config[:home], relative_path)
        result = []
        if File.directory?(real_path)
          if relative_path.present?
            result << details(File.expand_path('..',real_path),'..')
          end
          result += Dir[File.join(real_path,'*')].collect { |f| details(f) }
        elsif File.exists?(real_path)
          result += [details(real_path)]
        end
        result.sort do |a,b|
          if b.container?
            a.container? ? a.name.downcase <=> b.name.downcase : 1
          else
            a.container? ? -1 : a.name.downcase <=> b.name.downcase
          end
        end
      end

      def details(path,display=nil)
        if File.exists?(path)
          info = File::Stat.new(path)
          BrowseEverything::FileEntry.new(
            Pathname.new(File.expand_path(path)).relative_path_from(Pathname.new(config[:home])),
            [self.key,path].join(':'),
            display || File.basename(path),
            info.size,
            info.mtime,
            info.directory?
          )
        else
          nil
        end
      end

      def link_for(path)
        full_path = File.expand_path(path)
        file_size = File.size(full_path).to_i rescue 0
        ["file://#{full_path}", { file_name: File.basename(path), file_size: file_size }]
      end

      def authorized?
        true
      end
    end

  end
end
