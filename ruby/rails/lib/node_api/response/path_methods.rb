module NodeApi::Response::PathMethods
  
  def paths
      response_parsed['paths'].presence || []
  end

  def path
    paths.first
  end
  
  def error?
    super || path['error'].present?
  end

  def user_message
    super || path['error']['user_message']
  end
  
end