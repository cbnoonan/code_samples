module NodeApi
  class Delete < Base

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

    def delete
      begin
        req = JSON.parse(request.raw_post)
        req['paths'].each do |path_row|
          path = File.join(docroot, path_row['path'])
          begin
            stat = File.stat(path)
            if stat.directory?
              FileUtils.rm_r(path)
            else
              # FileUtils.rm_rf will swallow exceptions, but we want permissions errors
              # FileUtils.rm_r will swallow exceptions and reraise generic RuntimeException
              File.unlink(path)
            end
            paths << path_row
          rescue Errno::EACCES
            paths << path_row.merge(:error => { :code => 123, :user_message => 'Permission denied', :internal_message => $!.class.to_s })
          rescue
            paths << path_row.merge(:error => { :code => 123, :user_message => 'Internal error', :internal_message => $!.class.to_s })
          end
        end
      rescue
        Rails.logger.error "#{e.class} (#{e.message})\n  #{e.backtrace.join "\n  "}"
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
