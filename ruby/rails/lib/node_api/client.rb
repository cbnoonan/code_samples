class NodeApi::Client
  
  attr_accessor :url, :username, :password, :verify_ssl
  
  def initialize(url, options)
    self.url = url
    self.username = options.delete(:username)
    self.password = options.delete(:password)
    self.verify_ssl = options.delete(:verify_ssl) ? OpenSSL::SSL::VERIFY_PEER : false
    App.check_options(options)
  end
 
  def rest_client_site
    @rest_client_site ||= RestClient::Resource.new(url, 
      :headers => {
        :content_type => 'application/json',
      },
      :user => username, 
      :password => password, 
      :verify_ssl => verify_ssl,
      :headers => {
        :content_type => 'application/json',
      },
      :timeout => 30, :open_timeout => 10) # TODO: what should the timeouts be?
  end
  
  def ping
    http_response = rest_client_site['ping'].get
    NodeApi::Response::Ping.new(:http_response => http_response)
  rescue => e
    handle_exception(e, NodeApi::Response::Ping)
  end

  def info
    http_response = rest_client_site['info'].get
    NodeApi::Response::Info.new(:http_response => http_response)
  rescue => e
    handle_exception(e, NodeApi::Response::Info)
  end

  def space(paths)
    payload = { :paths => paths.map { |path| {:path => path} }  }
    http_response = rest_client_site['space'].post(payload.to_json)
    NodeApi::Response::Space.new(:http_response => http_response)
  rescue => e
    handle_exception(e, NodeApi::Response::Space)
  end
  
  def browse(path, options = {})
    payload = {
      :path => path.to_s,
      :sort => options[:sort].as_json,
      :filters => options[:filter].as_json,
    }
    payload[:skip] = options[:skip] if options[:skip]
    payload[:count] = options[:count] if options[:count]
    http_response = rest_client_site['files/browse'].post(payload.to_json)
    NodeApi::Response::Browse.new(:http_response => http_response)
  rescue => e
    handle_exception(e, NodeApi::Response::Browse)
  end

  def search(path, options = {})
    payload = {
      :path => path.to_s,
      :sort => options[:sort].as_json,
      :filters => options[:filter].as_json,
    }
    payload[:skip] = options[:skip] if options[:skip]
    payload[:count] = options[:count] if options[:count]
    http_response = rest_client_site['files/search'].post(payload.to_json)
    NodeApi::Response::Browse.new(:http_response => http_response)
  rescue => e
    handle_exception(e, NodeApi::Response::Browse)
  end

  def create_directory(directory)
    if illegal_name?(directory)
      return NodeApi::Response::Create.new(:user_message => 'Illegal name')
    end
    payload = { :paths => [ { :path => directory, :type => 'directory' } ] }
    http_response = rest_client_site['files/create'].post(payload.to_json)
    NodeApi::Response::Create.new(:http_response => http_response)
  rescue => e
    handle_exception(e, NodeApi::Response::Create)
  end
  
  def create_file(file, contents)
    if illegal_name?(file)
      return NodeApi::Response::Create.new(:user_message => 'Illegal name')
    end
    encoded_contents = Base64.encode64(contents)
    payload = { :paths => [ {
      :path => file,
      :type => 'file',
      :contents => encoded_contents
    } ] }
    http_response = rest_client_site['files/create'].post(payload.to_json)
    NodeApi::Response::Create.new(:http_response => http_response)
  rescue => e
    handle_exception(e, NodeApi::Response::Create)
  end

  def cat(file)
    #TODO: make :path
    payload = { :pathname => file }
    http_response = rest_client_site['files/cat'].post(payload.to_json)
    NodeApi::Response::Cat.new(:http_response => http_response)
  rescue => e
    handle_exception(e, NodeApi::Response::Cat)
  end
  
  def delete(files)
    payload = { :paths => files.map { |file| { :path => file } } }
    http_response = rest_client_site['files/delete'].post(payload.to_json)
    NodeApi::Response::Delete.new(:http_response => http_response)
  rescue => e
    handle_exception(e, NodeApi::Response::Delete)
  end

  def rename(path, source, destination)
    if [ path, source, destination ].any? { |p| illegal_name?(p) }
      return NodeApi::Response::Rename.new(:user_message => 'Illegal name')
    end
    payload = { :paths => [ { :path => path, :source => source, :destination => destination } ] }
    http_response = rest_client_site['files/rename'].post(payload.to_json)
    NodeApi::Response::Rename.new(:http_response => http_response)
  rescue => e
    handle_exception(e, NodeApi::Response::Rename)
  end

  def illegal_name?(path)
    path.split('/').any? do |segment|
      segment =~ %r{\\|\.\.|^\.$}
    end
  end

  def download(files, transfer_spec = {})
    payload = {
      :transfer_requests => [
        {
          :transfer_request => transfer_spec.merge({
            :paths => files.map { |source| { :source => source } }
          })
        }
      ]
    }
    http_response = rest_client_site['files/download_setup'].post(payload.to_json)
    NodeApi::Response::Download.new(:http_response => http_response)
  rescue => e
    handle_exception(e, NodeApi::Response::Download)
  end

  def upload(destination, transfer_spec = {})
    payload = {
      :transfer_requests => [
        {
          :transfer_request => transfer_spec.merge({
            :paths => [{ :destination => destination }]
          })
        }
      ]
    }
    http_response = rest_client_site['files/upload_setup'].post(payload.to_json)
    NodeApi::Response::Upload.new(:http_response => http_response)
  rescue => e
    handle_exception(e, NodeApi::Response::Upload)
  end

  def transfers_activity_ended(path, iteration_token)
    payload = { :path => path }
    payload[:iteration_token] = iteration_token if iteration_token
    http_response = rest_client_site['transfers/activity/ended'].post(payload.to_json)
    NodeApi::Response::TransfersActivityEnded.new(:http_response => http_response)
  rescue => e
    handle_exception(e, NodeApi::Response::TransfersActivityEnded)
  end

  def handle_exception(e, response_klass)
    case e
    when RestClient::BadRequest
      response_klass.new(:user_message => 'Bad request (may have sent a plain HTTP request to an HTTPS port)')
    when RestClient::SSLCertificateNotVerified
      response_klass.new(:user_message => 'SSL Verification failed')
    when OpenSSL::OpenSSLError
      response_klass.new(:user_message => 'SSL error')
    when Errno::ECONNREFUSED
      response_klass.new(:user_message => 'Connection refused')
    when Errno::EHOSTUNREACH
      response_klass.new(:user_message => 'Host unreachable')
    when RestClient::MovedPermanently
      response_klass.new(:user_message => 'Encountered redirect')
    when RestClient::Unauthorized
      response_klass.new(:user_message => 'Not authorized')
    when RestClient::ResourceNotFound
      response_klass.new(:user_message => 'The node does not support this feature')
    when RestClient::RequestTimeout
      response_klass.new(:user_message => 'Timed out connecting to node') 
    when SocketError
      message = Aspera::Error.message(e, :log_to_database => true, :default => "Connection error")
      response_klass.new(:user_message => message)
    else
      message = Aspera::Error.message(e, :log_to_database => true)
      # TODO: how is this differentiated from the node returning "Internal Error (ErrId=XX)"?
      response_klass.new(:user_message => message)
    end
  end

  def logger
    self.class.logger
  end
  
  class << self
    
    def logger
      Rails.logger
    end
    
  end
end