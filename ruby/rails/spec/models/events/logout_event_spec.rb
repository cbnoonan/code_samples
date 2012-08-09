require 'spec_helper'

describe LogoutEvent do
  let(:db_user) { Factory.create(:user) }
  let(:authorizable_user) { db_user.authorizable_user }
  let(:event) { 
    set_thread_globals(authorizable_user, '1.2.3.4')
    LogoutEvent.create_event
  }
  
  after(:all) do
    clear_thread_globals
  end

  describe '.create_event' do

    it "sets auth user fields" do
      event.data[:by_id].should == authorizable_user.id
      event.data[:by_username].should == authorizable_user.username
    end
    
  end
  
  describe '#process' do
    before(:each) do
      event.process
    end
    
    describe 'user feed' do
      let(:user_feed_item) { EventFeedItem.user.owner(authorizable_user).last }
    
      it "creates user feed items" do
        user_feed_item.event_type_name.should == 'Logout'
        user_feed_item.description.should == 'You logged out from 1.2.3.4'
      end
    end
    
    describe 'admin directory feed' do
      let(:dir_feed_item) { EventFeedItem.admin.owner(authorizable_user.directory).last }
      
      it "creates directory feed item" do
        dir_feed_item.event_type_name.should == 'Logout'
        dir_feed_item.description.should == "User '#{authorizable_user.username}' logged out from 1.2.3.4"
      end
    end
    
  end
  
end