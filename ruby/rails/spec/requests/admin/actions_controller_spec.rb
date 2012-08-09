require 'spec_helper'

describe 'actions_controller' do
  include RequestHelpers
  include TokenHelpers

  let(:index_path) { admin_actions_path }

  before(:each) do
    Tasks::Init.init
    admin_login
    Event.all.map(&:process)
  end

  context "search form" do

    before(:each) do
      visit index_path
    end

    it "is hidden", :js => true do
      page.should have_selector("a", :text => "Search")
      page.should_not have_selector("label", :text => "From")
    end
    
    it "shows", :js => true do
      page.find("a", :text => "Search").click
      page.should have_selector("a", :text => "Hide Search")
      page.should have_selector("label", :text => "From")
    end

    it "searches", :js => true do
      page.find("a", :text => "Search").click
      fill_in "from_date", :with => "2010-01-01"
      fill_in "from_time", :with => "01:00"
      click_button "Search"
      page.should have_selector("a", :text => "Hide Search")
      page.should have_selector("label", :text => "From")
      page.should_not have_selector(".flash_error")
    end

    it "searches for events", :js => true do
      page.find("a", :text => "Search").click
      add_token("LocalUserCreated")
      click_button "Search"
      should_have_token("LocalUserCreated")
      page.should_not have_selector(".flash_error")     
    end

    it "does not search for unrecognized events", :js => true do
      visit admin_actions_path(:events => "LocalUserCreated,UnrecognizedEvent,FailedLogin")
      should_have_token("LocalUserCreated")
      should_have_token("FailedLogin")
      should_not_have_token("UnrecognizedEvent")
      page.should_not have_selector(".flash_error")     
    end

    it "fails with invalid time", :js => true do
      page.find("a", :text => "Search").click
      fill_in "from_date", :with => "2010-01-01"
      fill_in "from_time", :with => "25:00"
      click_button "Search"
      page.should have_selector("a", :text => "Hide Search")
      page.should have_selector("label", :text => "From")
      should_have_flash(:text => "Invalid 'From' date or time")
    end

  end
  
  
end