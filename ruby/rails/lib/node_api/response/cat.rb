class NodeApi::Response::Cat < NodeApi::Response::Base
  
  def error?
    user_message
  end
  
  def file_contents
    Base64.decode64(response_parsed['file_contents'])
  end

end
