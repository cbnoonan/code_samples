# IMPORTANT: Currently this is for same-node only

module NodeApi
  class Copy < Base

    attr_accessor :uuid

    def copy
      paths = JSON.parse(request.raw_post)
            
      paths.each do |d|
        # 1. insert a row into the db / mimics the connection to a node
        fake_api_call = FakeApiCall.new()
        fake_api_call.message = 'BEGIN_COPY'

        # 2. check failure cases  
        unless fake_api_call.save
          next self.error = {:code => 1000, :user_message => 'There was a problem...'} 
        end
        if (d['source'] == d['destination'])
          next self.error = {:code => 2000, :user_message => 'Source and Destination are the same'} 
        end
                
        # 3. try copying
        if File.directory?(d['source'])
          FileUtils.cp_r(d['source'], d['destination'])
          fake_api_call.message = 'COPY_COMPLETE'      
        elsif File.file?(d['source'])
          FileUtils.cp(d['source'], d['destination'])
          fake_api_call.message = 'COPY_COMPLETE'
        end
        fake_api_call.save

        self.uuid = SecureRandom.uuid
      end
    rescue => e
      self.error = {:code => 5000, :user_message => 'There was a problem copying'} 
      false
    end
    
    def result
      {
        :uuid => self.uuid,
        :error => self.error,
      }
    end
  end
     
end
