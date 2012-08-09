require 'spec_helper'

describe Event do
  def au
    @au ||= begin
      attrs = {:username => 'un', :first_name => 'f', :last_name => 'l', :email => 'email@example.com'}
      Authorizable::User.new.tap do |auth_user|
        attrs.each { |k, v| auth_user.send("#{k}=", v) }
        auth_user.stub!(:id).and_return(42)
      end
    end
  end
  
  before(:each) do
    Authorizable::User.current = nil
    Authorizable::User.ip_address = nil
  end
  
  describe '.current_user' do
    
    it 'all nil if user not set' do
      Authorizable::User.current.should be_nil
      Event.current_user.should be_nil
    end
    
    it "return values if current user set" do
      Authorizable::User.current = au
      Event.current_user.should == au
    end
    
  end
  
  describe '.ip_address' do
    
    it "is nil if not set" do
      Event.ip_address.should be_nil
    end
    
    it "returns value if set" do
      Authorizable::User.ip_address = '1.2.3.4'
      Event.ip_address.should == '1.2.3.4'
    end
    
  end
  
  describe '.default_data' do
    before(:each) do
      @now = Time.now
      Time.stub!(:now).and_return(@now)
    end
    
    it "all nil if nothing set (except time)" do
      Event.default_data.should == {
        :event => 'Event',
        :by_id => nil,
        :by_username => nil,
        :by_full_name => nil,
        :by_email => nil,
        :by_email_with_display_name => nil,
        :ip_address => nil,
        :at => @now,
      }
    end
    
    it "returns values set in controller" do
      Authorizable::User.current = au
      Authorizable::User.ip_address = '1.2.3.4'
      Event.default_data.should == {
        :event => 'Event',
        :by_id => 42,
        :by_username => 'un',
        :by_full_name => 'f l',
        :by_email => 'email@example.com',
        :by_email_with_display_name => "\"f l\" <email@example.com>",
        :ip_address => '1.2.3.4',
        :at => @now,
      }
    end
    
  end
  
  describe '.node_data' do
    let(:node) { Factory.create(:node, :name => 'name', :host => 'example.com', :api_port => 443, :api_username => 'api_user')}
    let(:nd) { node.stub!(:id).and_return(42); Event.node_data(node) }
    
    it "sets node data" do
      nd[:node_id].should == 42
      nd[:node_name].should == 'name'
      nd[:node_user_at_url].should == 'api_user@https://example.com:443'
    end

    it "defines getters" do
      event = NodeCreatedEvent.create_event(node)
      event.node_id.should == node.id
      event.node_name.should == 'name'
      event.node_user_at_url.should == 'api_user@https://example.com:443'
    end
  end
  
  describe '.share_data' do
    let(:share) { Factory.create(:share, :name => 'share_name', :directory => '/dir') }
    let(:sd) { Event.share_data(share) }
    
    it "sets share data" do
      sd[:share_id].should == share.id
      sd[:share_name].should == 'share_name'
      sd[:share_directory].should == '/dir'
      sd[:node_id].should == share.node.id
    end
    
    it "defines getters" do
      event = ShareCreatedEvent.create_event(share)
      event.share_id.should == share.id
      event.share_name.should == 'share_name'
      event.share_directory.should == '/dir'
      event.node_name.should == share.node.name
    end
  end
  
end
