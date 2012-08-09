class NodeApi::Response::Upload < NodeApi::Response::Base

  def error?
    super || error_from_xfer_session?
  end

  def error_from_xfer_session?
    error_from_xfer_session.present?
  end
  
  def user_message
    super || error_from_xfer_session
  end

  def error_from_xfer_session
    if response_parsed['transfer_specs']
      response_parsed['transfer_specs'].each do |xfer_session|
        return (xfer_session['error'] || {})['user_message']
      end
    end
    nil
  end

  def schema
    nil
  end
  
end
