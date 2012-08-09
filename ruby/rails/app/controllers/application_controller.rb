class ApplicationController < ActionController::Base
  include TabNav::ControllerMethods
  
  protect_from_forgery
  
  before_filter :do_not_cache
  before_filter :log_level
  before_filter :clear_footnotes
  before_filter :load_settings
  before_filter :set_ip_address
  before_filter :authenticate
  before_filter :deleted_account
  before_filter :set_current_user  # keep this early so events can make use of it
  before_filter :set_time_zone
  before_filter :expired_account
  before_filter :disabled_account
  before_filter :check_session_timeout
  before_filter :check_password_reset
  before_filter :set_protocol_host_port
  before_filter :set_error_count
  before_filter :update_last_request_at, :if => :logged_in?
  
  clear_helpers
  helper :link, :table
  
  helper_method :current_user
  helper_method :logged_in?

  API_LOGIN = 'api.login'
  APP_LOGIN = 'app.login'
  APP_ADMIN = 'app.admin'
  
  BUILD_IN_PERMISSIONS = [APP_ADMIN, APP_LOGIN, API_LOGIN]
  
  # or maybe this should look like a 500?
  NOT_AUTHORIZED_MESSAGE = "You are not authorized to view the requested page."
  ACCOUNT_DISABLED_MESSAGE = 'Your account has been disabled.  Contact your admin.'
  ACCOUNT_EXPIRED_MESSAGE = 'Your account has expired.  Contact your admin.'
  ACCOUNT_NOT_FOUND_MESSAGE = 'Account not found.  Contact your admin.'
  
  begin 'exception handling'
    
    if App.handle_uncaught_errors?

      rescue_from Exception do |e|
        @error = Aspera::Error.handle(e, :log_to_database => true)
        if request.xhr?
          # redirect to error page using window.location (Firefox < version 7 doesn't do redirects
          # in ajax requests properly) - https://bugzilla.mozilla.org/show_bug.cgi?id=553888
          render 'shared/redirect_to_error', :status => :internal_server_error
        else
          redirect_to error_500_path(:id => @error.database_id)
        end
      end
    
      rescue_from ActiveRecord::RecordNotFound do
        redirect_to not_found_path
      end

    end
    
  end
  
  protected
  
  
  def set_ip_address
    Authorizable::User.ip_address = request.remote_ip
  end
  
  def set_current_user
    Authorizable::User.current = current_user.try(:authorizable_user)
  end
  
  def set_protocol_host_port
    Authentication::Server::Service.protocol_host_port = protocol_host_port
  end

  def authenticate
    redirect_to_login unless logged_in?
  end

  def deleted_account
    if current_user && current_user.authorizable_user.nil?
      session.delete(:user)
      reset_session
      flash[:error] = ACCOUNT_NOT_FOUND_MESSAGE
      redirect_to_login
    end
  end

  def expired_account
    if logged_in? && current_user.account_expired?
      reset_session
      flash[:warning] = ACCOUNT_EXPIRED_MESSAGE
      redirect_to_login
    end
  end

  def disabled_account
    if logged_in? && current_user.disabled?
      reset_session
      flash[:warning] = ACCOUNT_DISABLED_MESSAGE
      redirect_to_login
    end
  end
  
  def check_session_timeout
    if session[:expires_at].blank? || session[:expires_at] < Time.now
      SessionTimedOutEvent.create_event
      reset_session
      flash[:warning] = 'Your session has timed out. Log in again to continue.'
      redirect_to_login
    else
      reset_session_expiration
    end
  end
  
  def reset_session_expiration(time_out_at = nil)
    default_timeout_at = Aspera::Config::UserSecurity.load_settings.session_timeout.minutes.from_now
    # TODO: this needs to deal w/TZ
    expires_at = [default_timeout_at, time_out_at].compact.min
    session[:expires_at] = expires_at
  end

  def redirect_to_login
    if request.xml_http_request?
      session[:return_to] = request.referer
      render :js => %|document.location.href = "#{login_path}";|
    else
      if request.get?
        session[:return_to] = request.fullpath
      else
        session[:return_to] = root_path #request.referer
      end
      redirect_to login_path
    end
  end

  def check_password_reset
    if logged_in? && current_user.password_reset_required?
      reset_session_expiration(1.minute.from_now)
      flash[:warning] = current_user.password_reset_warning
      redirect_to preferences_password_path
    end
  end
  
  def admin
    unless current_user.admin?
      flash[:error] = NOT_AUTHORIZED_MESSAGE
      redirect_to root_url
      false
    end
  end

  def current_user
    @current_user ||= User.new(session[:user]) if session[:user]
  end

  def set_authorizable_user
    @authorizable_user = current_user.authorizable_user
  end
  
  def logged_in?
    current_user.present?
  end

  def set_time_zone
    if logged_in?
      Time.zone = current_user.effective_time_zone
    end
  end
  
  def set_error_count
    if logged_in? && current_user.admin?
      @error_count = Aspera::Correctness::Item.errors.count
    end
  end
  
  def update_last_request_at
    current_user.touch(:last_request_at)
  end
  
  def protocol_host_port
    "#{request.protocol}#{request.host_with_port}"
  end

  def do_not_cache
    response.headers["Cache-Control"] = "no-cache, no-store, max-age=0, must-revalidate"
    response.headers["Pragma"] = "no-cache"
    response.headers["Expires"] = "Fri, 01 Jan 1990 00:00:00 GMT"
  end

  def load_settings
    App.protocol_host_port = nil
    # TODO: load config settings in a before filter once.
  end
  
  def clear_footnotes
    if App.development?
      Footnotes::Notes::LdapNote.arr.clear
      Footnotes::Notes::QueriesNote.sql.clear
    end
  end

  def log_level
    Rails.logger.level = Aspera::Config::Logging.web_application
  end

end
