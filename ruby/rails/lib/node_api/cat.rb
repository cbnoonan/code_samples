module NodeApi
  class Cat < Base

    MAX_FILE_SIZE = 1.megabyte
    
    attr_accessor :file_contents

    def initialize(*args)
      super(*args)
    end

    def cat
      begin
        # FIXME: sanitize path?  Can an apiuser create directories anywhere? download any files?
        req = JSON.parse(request.raw_post)
        path = req['pathname']
        
        if path_contains_dotdot?(path)
          self.error[:user_message] = "Path contains invalid characters" 
        elsif File.size(path) > MAX_FILE_SIZE
          self.error[:user_message] = "File too big"
        else
          self.file_contents = File.read(path)
          return true
        end
      rescue Errno::EACCES
        self.error[:user_message] = 'Permission denied'
      rescue Errno::ENOENT
        self.error[:user_message] = 'No such file'
      rescue => e
        self.error[:user_message] = Aspera::Error.message(e, :log_to_database => true)
      end
      self.file_contents = nil
      false
    end

    def result
      {
        # Reason to base64 the file contents:
        # http://stackoverflow.com/questions/1443158/binary-data-in-json-string-something-better-than-base64/1443240#1443240
        :file_contents => Base64.encode64(self.file_contents),
        :error => self.error,
      }
    end
  end

end
