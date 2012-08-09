class Admin::BaseController < ApplicationController
  layout 'admin'
  before_filter :admin
  helper 'admin/config/base'
  current_tab :admin
  
  before_filter :count_errors
  
  def index
    render :text => '', :layout => true
  end
  
  private
  
  def self.current_item(*args)
    options = args.extract_options!

    before_filter(options) do |controller|
      controller.send(:current_item, *args)
    end
  end

  def current_item(*args)
    @current_item = args.first
  end
  
  def compute_layout
    if ['index', 'new', 'create'].include?(action_name)
      'admin'
    else
      'two_level_admin'
    end
  end

  def count_errors
    @directory_error_count = AuthorizableDirectory.where('status IS NOT NULL').count
    @group_error_count = Authorizable::Group.where('status IS NOT NULL').count
    @user_error_count = Authorizable::User.where('status IS NOT NULL').count
    @self_registration_error_count = SelfRegistration.unprocessed.count
    @smtp_error_count = SmtpServer.where('status IS NOT NULL').count
  end

end