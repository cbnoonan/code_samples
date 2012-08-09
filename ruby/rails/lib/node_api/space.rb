module NodeApi
  class Space < Base
    
    attr_accessor :results_for_paths
    
    def initialize(*args)
      super(*args)
    end
    
    def space
      self.results_for_paths = request_path_names.map { |path_name| result_for_path(path_name) }
      true
    rescue => e
      Rails.logger.error "#{e.class} (#{e.message})\n  #{e.backtrace.join "\n  "}"
      self.error = { :user_message => 'Internal error' }
      false
    end
    
    def result_for_path(path_name)
      path_result = {:path => path_name}
      space_checker = AsperaSharesSpaceChecker.new(path_name)
      path_result.merge({
        :bytes_total => space_checker.bytes,
        :bytes_free => space_checker.bytes_free,
        :percent_free => space_checker.percent_free,
      })
    rescue => e
      user_message = "Error checking free space"
      internal_message = "#{e.class}: #{e.message}"
      path_result.merge(:error => {:user_message => user_message, :internal_message => internal_message})
    end
    
    def result
      { :paths => results_for_paths }
    end
  end
  
end