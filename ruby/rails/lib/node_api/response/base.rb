class NodeApi::Response::Base
  extend ActiveSupport::Memoizable

  attr_accessor :http_response
  attr_accessor :error
  attr_accessor :response_parsed
  attr_accessor :validator, :validation_message

  def initialize(attributes = {})
    unless attributes.has_key?(:user_message) || attributes.has_key?(:http_response)
      raise ArgumentError, "An http_response or user_message must be specified"
    end
    
    self.http_response = attributes[:http_response]
    self.response_parsed = {}
    
    if attributes[:user_message].present?
      self.response_parsed = { 'error' => { 'user_message' => attributes[:user_message] } }
      
    elsif http_response.present?
      parse_http_response
    end
  end

  def error
    validation_message.presence || response_parsed['error']
  end

  def error?
    !!error
  end

  def user_message
    validation_message.presence || (error && error['user_message'])
  end

  def success?
    !error?
  end
  
  def valid?
    validator.validate(response_parsed).tap do |result|
      self.validation_message = "response#{validator.message}" unless result
    end
  end
  
  def schema
    raise "Not implemented"
  end

  def error_schema
    {
      :type => Hash,
      :keys => [{
        'error' => {
          :type => Hash, 
          :keys => [
            {
              'user_message' => {:type => String}
            }
          ]
        }
      }]
    }
  end
    
  def validator
    @validator ||= JsonValidator.new(schema)
  end

  def parse_http_response
    self.response_parsed = ActiveSupport::JSON.decode(http_response)
    log_invalid_response unless valid?
  rescue => e # Invalid JSON string raises StandardError
    raise unless e.message =~ /Invalid JSON string/
    log_invalid_json
  end

  def log_invalid_response
    id = ErrorLog.log_error({
      :message => "#{self.class.name}: Invalid response from node: #{validation_message}",
      :description => JSON.pretty_generate(response_parsed),
    }).id
    self.validation_message = nil
    self.response_parsed = { 'error' => { 'user_message' => "Invalid response from node (ErrId=#{id})" } }
  end

  def log_invalid_json
    id = ErrorLog.log_error({
      :message => "#{self.class.name}: Invalid response from node",
      :description => http_response,
    }).id
    self.response_parsed = { 'error' => { 'user_message' => "Invalid response from node (ErrId=#{id})" } }
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