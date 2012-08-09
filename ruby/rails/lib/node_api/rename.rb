module NodeApi
  class Rename < Base

    attr_accessor :paths

    def initialize(*args)
      super(*args)
      self.paths = []
    end

    def docroot
      @docroot ||= begin
        if Rails.application.config.respond_to? :docroot
          Rails.application.config.docroot
        else
          Pathname.new '/'
        end
      end
    end

    def rename
      begin
        req = JSON.parse(request.raw_post)
        req['paths'].each do |path_row|
          begin
            path = File.join docroot, path_row['path']
            old_path = File.join(path, path_row['source'])
            new_path = File.join(path, path_row['destination'])
            unless File.exist?(new_path)
              File.rename(old_path, new_path)
              paths << path_row
            else
              paths << path_row.merge(:error => { :code => 123, :user_message => 'Path already exists'})
            end
          rescue Errno::EACCES
            paths << path_row.merge(:error => { :code => 123, :user_message => 'Permission denied', :internal_message => $!.class.to_s })
          rescue
            paths << path_row.merge(:error => { :code => 123, :user_message => 'Internal error', :internal_message => $!.class.to_s })
          end
        end
      rescue
        self.error = { :code => 7000, :user_message => 'Internal error' }
        return false
      end
      true
    end
    
    def result
      { :paths => self.paths }
    end
  end

end