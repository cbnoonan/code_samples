class LogoutEvent < Event
  
  def process
    create_feed_items
    super
  end
  
  def create_feed_items
    common_attributes = {
      :feed_subject => authorizable_user,
      :feed_object => authorizable_user,
    }

    create_user_feed_item(common_attributes.merge({
      :feed_owner => authorizable_user,
      :description => "You logged out from #{ip_address}",
    }))

    create_admin_feed_item(common_attributes.merge({
      :feed_owner => authorizable_user.directory,
      :description => "User '#{by_username.to_s.truncate(30)}' logged out from #{ip_address}",
      :body => body_user_info.join("\n"),
    }))
  end
  
  class << self
    
    def create_event
      create_typed_event(default_data)
    end
    
  end
  
end