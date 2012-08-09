class AllActivityController < ApplicationController
  
  include LoadMoreControllerModule
  include Admin::ActionsControllerModule
  helper Admin::ActionsHelper
  
  layout 'node_share'
  current_tab :level_1, :home
  
  private
  
  def options_for_actions
    {
      :collection_scope => EventFeedItem.user.owner(current_user.authorizable_user),
      :feed_type => :all_activity,
      :title => "All Activity",
    }
  end
  
end