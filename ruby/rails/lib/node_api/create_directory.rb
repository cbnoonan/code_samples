module NodeApi
  class CreateDirectory < Base

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

    def create
      begin
        req = JSON.parse(request.raw_post)
        req['paths'].each do |path_row|
          begin
            Dir.mkdir(File.join(docroot, path_row['path']))
            paths << path_row
          rescue Errno::EACCES
            paths << path_row.merge(:error => { :code => 123, :user_message => 'Permission denied', :internal_message => $!.class.to_s })
          rescue Errno::EEXIST
            paths << path_row.merge(:error => { :code => 123, :user_message => 'File exists', :internal_message => $!.class.to_s })
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