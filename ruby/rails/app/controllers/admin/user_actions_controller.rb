class Admin::UserActionsController < Admin::UserEditController
  
  include LoadMoreControllerModule
  include Admin::ActionsControllerModule
  helper Admin::ActionsHelper
  
  current_tab :level_2, :activity
    
  private 

  def options_for_actions
    {
      :collection_scope => EventFeedItem.admin.subject(@user),
      # :feed_type => :user_admin,
    }
  end

end
