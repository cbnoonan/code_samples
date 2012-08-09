class SaveRestoreConfigController < TabbedController
  helper :console_configuration
  layout 'console_configuration'
  before_filter :major_tab_console_configuration
  before_filter :minor_tab_save_restore_config
  before_filter :admin_filter
  before_filter :ami?
  
  def index
  end
  
  def save
    at = AppTar::App.new
    if at.save
      send_file(at.save_path, :filename => at.save_download_filename)      
    else
      flash[:error] = at.error_message
      redirect_to :action => 'index'
    end
  end
  
  def restore
    at = AppTar::App.new
    if at.restore(params[:config_file])
      flash[:notice] = 'Configuration restored'
    else
      flash[:error] = at.error_message
    end
    redirect_to :action => 'index'
  end
  
end
  
