class Event < ActiveRecord::Base
  include Aspera::ActiveRecord::Common

  cattr_accessor :suspend_event_creation
   
  validates :type, :presence => true
  
  attr_accessible :event_type, :data
  
  belongs_to :event_type
  
  serialize :data, Hash
  
  after_create :queue_delayed_job
  
  # Default implementation.  Subclasses should implement their own #process()
  # to have anything done.
  def process
    update_attribute :processed, true
    Authorizable::User.current = nil
    Authorizable::User.ip_address = nil
  end
  
  # Every event has a delayed_job row created.
  def queue_delayed_job
    delay.process
  end
  
  def create_feed_item(attributes)
    EventFeedItem.create!(attributes.merge(
      :event_id => self.id,
      :event_type_name => event_type_name,
      :ip_address => data[:ip_address],
      :event_at => data[:at],
    ))
  end
  
  def create_admin_feed_item(attributes)
    create_feed_item(attributes.merge(:feed_owner_role => EventFeedItem::ROLE_ADMIN))
  end
  
  def create_user_feed_item(attributes)
    create_feed_item(attributes.merge(:feed_owner_role => EventFeedItem::ROLE_USER))
  end

  
  def event_type_name
    self.class.name.sub(/Event$/, '')
  end
  
  def at
    created_at
  end
  
  def ip_address
    data[:ip_address]
  end
  
  # Returns Authorizable::User if user is still in db.
  def authorizable_user
    @authorizable_user ||= Authorizable::User.find_by_id(by_id)
  end
  
  def by_username
    data[:by_username]
  end
  
  def by_email; data[:by_email]; end
  def by_id; data[:by_id]; end
  def by_full_name; data[:by_full_name]; end
  def node_id; data[:node_id]; end
  def node_name; data[:node_name]; end
  def node_user_at_url; data[:node_user_at_url]; end
  def share_id; data[:share_id]; end
  def share_directory; data[:share_directory]; end
  def share_name; data[:share_name]; end
  
  
  
  def username
    data[:by_username]
  end
  
  # Adds some aliases for template maintainers.
  def data_with_user_fields
    data.merge({
      :username => data[:by_username],
      :full_name => data[:by_full_name],
      :email => data[:by_email],
    })
  end
  
  def share
    @share ||= Node::Share.find_by_id(data[:share_id])
  end
  
  def node
    @node ||= Node::Node.find_by_id(data[:node_id]) || share.try(:node)
  end
  
  def body_user_info
    [
      "Username: #{by_username}",
      "Full name: #{by_full_name}",
      "Email: #{by_email}"
    ]
  end

  def body_node_info
    [ 
      "Node Name: #{node_name}",
      "Connect Info: #{node_user_at_url}",
      "Node Id: #{node_id}",
    ]
  end
  
  def body_share_info
    [
      "Share Name: #{share_name}",
      "Directory: #{share_directory}",
      "Share Id: #{share_id}",
    ]
  end
  
  def body_node_user_info
    body_node_info + body_user_info
  end
  
  def body_node_share_user_info
    body_node_info + body_share_info + body_user_info
  end
  
  def set_thread_globals
    Authorizable::User.current = authorizable_user
    Authorizable::User.ip_address = data[:ip_address]
  end
  
  class << self

    def create_typed_event(data)
      return if suspend_event_creation
      
      create!({
        :event_type => event_type,
        :data => data
      })
    end

    def current_user
      Authorizable::User.current
    end
    
    # Returns ip address set in controller (presumably)
    def ip_address
      Authorizable::User.ip_address
    end
    
    def default_data(authorizable_user = current_user)
      email_address = authorizable_user.try(:email)
      full_name = authorizable_user.try(:full_name)
      {
        :event => self.to_s,
        :at => Time.now,
        :ip_address => ip_address,
        :by_id => authorizable_user.try(:id),
        :by_username => authorizable_user.try(:username),
        :by_full_name => full_name,
        :by_email => email_address,
        :by_email_with_display_name => authorizable_user.try(:email_with_display_name),
      }
    end

    def node_data(node)
      {
        :node_id => node.id,
        :node_name => node.name,
        :node_user_at_url => node.user_at_url,
      }
    end
    
    def share_data(share)
      {
        :share_id => share.id,
        :share_name => share.name,
        :share_directory => share.directory,
      }.merge(node_data(share.node))
    end
    
    def event_type
      EventType.find_by_event_class(self.to_s)
    end
  
  end
  
end