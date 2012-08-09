# Namespace for utility functions:
#
# Checking environment:
#
#   App.development?            # right way
#   Rails.env == 'developemnt'  # wrong; subject to typo
#   Rails.env.developemnt?      # wrong; subject to typo
#   
module App

  NOT_PINGABLE = 'not pingable'
  NOT_INFOABLE = 'not infoable'
  NOT_BROWSABLE = 'not browsable'
  NODE_ERROR = 'node error'
  HOST_ERROR = 'host error'

  module_function

  def ami?
    @ami ||= Aspera::Config::Ami.enabled?
  end

  def development?
    Rails.env == 'development'
  end
  
  def not_development?
    !development?
  end
  
  def test?
    Rails.env == 'test'
  end

  def not_test?
    !test?
  end
  
  def production?
    Rails.env == 'production'
  end
  
  def not_production?
    !production?
  end
  
  # Pathname#to_s is expensive, so use App::rails_root when you want the string.
  def rails_root
    @rails_root ||= Rails.root.to_s
  end
  
  def db_config(reload = false)
    if reload || @db_config.nil?
      @db_config = Rails.configuration.database_configuration[Rails.env]
    else
      @db_config
    end
  end
  
  def protocol_host_port=(v)
    @protocol_host_port = v
  end
  
  def protocol_host_port
    @protocol_host_port ||= String.new.tap do |php|
      php << "#{protocol}://#{host}"
      php << ":#{port}" if port.present?
    end
  end
  
  def protocol
    Aspera::Config::WebServer.tls ? "https" : "http"
  end
  
  def host
    Aspera::Config::WebServer.host
  end
  
  def port
    Aspera::Config::WebServer.port
  end

  def handle_uncaught_errors?
    App.test? || !Rails.application.config.consider_all_requests_local
  end
  
  def login_token_duration
    1.day
  end
  
  def secret
    SecretFile.reload_file if development?
    raise "App.secret is nil. config/aspera/secret.rb must set App.secret" if @secret.nil?
    @secret
  end
  
  def secret=(val)
    @secret = val
  end
  
  def per_page
    50
  end
  
  # ActiveRecord-like attribute assignment.
  # 
  #   attr_accessor :foo, :bar
  #
  #   def initialize(attributes)
  #     # this
  #     App.assign_attributes(self, attributes)
  #
  #     # is almost the same as
  #     self.foo = attributes["foo"]
  #     self.bar = attributes["bar"]
  #   end
  def assign_attributes(object, attributes)
    attributes.each do |key, value|
      begin
        method = "#{key}="
        object.send method, value
      rescue => e
        raise Aspera::Error::ArgumentError, "error assigning #{method} #{value}"
      end
    end
  end
  
  # Raises error if _object_ is not an instance of _klass_.
  def check_class(object, klass)
    unless object.instance_of?(klass)
      raise(Aspera::Error::ArgumentError, "expected: #{klass}, got: #{object.class}") 
    end
  end
  
  # Raises error if _object_ is not an instance of _klass_ or one of its superclasses.
  def check_subclass(object, klass)
    unless object.kind_of?(klass)
      message = "expected: #{klass} (or subclass), got: #{object.class}"
      raise(Aspera::Error::ArgumentError, message) 
    end
  end
  
  # Typically called in constructors to make sure no invalid options are passed.
  # 
  #   def initialize(arg, options = {})
  #     self.foo = options.delete(:foo)
  #     App.check_options(options)
  #   end
  def check_options(options)
    unless options.empty?
      message = "invalid option(s): #{options.inspect}"
      raise(Aspera::Error::InvalidOptionError, message)
    end
  end
  
  begin 'time zone methods'
    
    # Returns Array of time zones for use in select options
    #
    #   [
    #     ["(GMT-10:00) Hawaii", "Hawaii"],
    #     ["(GMT-09:00) Alaska", "Alaska"],
    #     ...
    #   ]
    # 
    # The Time.zone= method requires the short version (e.g. "Hawaii") but we want to
    # show the user the long version (e.g. "(GMT-10:00) Hawaii").
    # 
    #   App.time_zones(true)   # U.S. zones only
    #   App.time_zones(false)  # all zones
    #   App.time_zones()       # U.S. or all based on Localization configuration
    def time_zones(us_time_zones_only = nil)
      us_time_zones_only = Aspera::Config::Localization.load_settings.us_time_zones_only if us_time_zones_only.nil?
      if us_time_zones_only
        us_zones
      else
        all_zones
      end
    end
  
    def us_zones
      @us_zones ||= ActiveSupport::TimeZone.us_zones.map { |z| [z, z.name]  }
    end
    
    def all_zones
      @all_zones ||= ActiveSupport::TimeZone.all.map { |z| [z, z.name] }
    end

    # Look-up hash.  Keys are zones without offset, values with offset.
    def time_zone_hash
      @time_zone_hash ||= Hash.new.tap do |tz_hash|
        all_zones.each do |long, short|
          tz_hash[short] = long
        end
      end
    end
  end

  # Copied from ActionView::Helpers::TextHelper.pluralize
  def pluralize(count, singular, plural = nil)
    "#{count || 0} " + ((count == 1 || count =~ /^1(\.0+)?$/) ? singular : (plural || singular.pluralize))
  end
  
  def read_binary_file(path)
    open(path, "rb") {|io| io.read }
  end
  
  def backup(options)
    Aspera::BackupRestore.backup(options)
  end

  def restore(options)
    Aspera::BackupRestore.restore(options)
  end

  def qa_credentials_file
    "#{Rails.root}/config/aspera/qa_credentials.yml"
  end
  
end