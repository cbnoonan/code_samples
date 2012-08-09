require 'uri'

module NodeApi
  class Base
  
    attr_accessor :params, :request, :error

    def initialize(params, request)
      self.params = params
      self.request = request
      self.error = {}
    end
    
    def request_parsed
      @request_parsed ||= JSON.parse(request.raw_post)
    end
    
    # Presumably returns something like:
    #   [ { "path" => "p1", "path" => "p2"} ]
    def request_path_hashes
      request_parsed["paths"]
    end
    
    def request_path_names
      request_path_hashes.map { |path_hash| path_hash["path"] }
    end
    
    def path_contains_dotdot?(path)
      path =~ %r{^\.\.$} || 
      path =~ %r{^\.\./} ||
      path =~ %r{/\.\.$} || 
      path =~ %r{/\.\./}
    end
    
  end
     
end