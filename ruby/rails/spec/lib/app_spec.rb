require 'spec_helper'

describe App do
  
  describe 'constants' do
    it 'NOT_BROWSABLE' do
      App::NOT_BROWSABLE.should == 'not browsable'
    end
  end
  
  describe '.rails_root' do
    it "returns Rails.root.to_s" do
      App.rails_root == Rails.root.to_s
    end
    
    it "caches its result" do
      App.rails_root.object_id == App.rails_root.object_id
    end
  end
  
  describe 'environments' do
    
    it "(not) development?" do
      App.development?.should be_false
      Rails.stub!(:env).and_return(ActiveSupport::StringInquirer.new 'development')
      App.development?.should be_true
      App.not_development?.should be_false
    end

    it "(not) test?" do
      App.test?.should be_true
      App.not_test?.should be_false
      Rails.stub!(:env).and_return(ActiveSupport::StringInquirer.new 'foo')
      App.test?.should be_false
      App.not_test?.should be_true
    end

    it "(not) production?" do
      App.production?.should be_false
      Rails.stub!(:env).and_return(ActiveSupport::StringInquirer.new 'production')
      App.production?.should be_true
      App.not_production?.should be_false
    end

  end
  
  describe '.assign_attributes' do
    class AppFoo
      attr_accessor :a, :b
      def initialize(attributes)
        App.assign_attributes(self, attributes)
      end
    end
    
    it "assigns attributes" do
      foo = AppFoo.new(:a => 1, :b => 2)
      foo.a.should == 1
      foo.b.should == 2
    end
    
    it "doesn't require all attributes" do
      foo = AppFoo.new(:a => 1)
      foo.a.should == 1
      foo.b.should be_nil
    end
    
    it "raise error on bad argument" do
      expect { AppFoo.new(:c => 3) }.to raise_error(Aspera::Error::ArgumentError)
    end
  end

  describe '.check_class' do
    
    it "raises error if wrong class" do
      expect { App.check_class("foo", Fixnum) }.to raise_error(Aspera::Error::ArgumentError)
    end
    
    it "does nothing if correct class" do
      expect { App.check_class("foo", String) }.to_not raise_error
    end
    
  end
  
  describe '.check_subclass' do
    
    it "raises error if not a subclass" do
      expect { App.check_subclass("foo", Fixnum) }.
        to raise_error(Aspera::Error::ArgumentError)
    end
    
    it "does nothing if correct class" do
      si = ActiveSupport::StringInquirer.new
      expect { App.check_subclass(si, String) }.to_not raise_error
    end
    
  end
  
  describe '.check_options' do
    
    it "raises error if not empty" do
      expect { App.check_options({:foo => 'bar'}) }.
        to raise_error(Aspera::Error::InvalidOptionError)
    end
    
    it "does nothing if empty" do
      expect { App.check_options({}) }.to_not raise_error
    end
    
  end
  
  describe '.secret' do
    
    it 'is set in config/aspera/secret.rb' do
      lines = File.readlines("#{Rails.root}/config/aspera/secret.rb")
      lines[1].should == "App.secret = '#{App.secret}'\n"
    end

  end
  
  describe '.time_zones' do
    
    it "can be forced to return us zones" do
      App.time_zones(true).map(&:first).should == ActiveSupport::TimeZone.us_zones
    end
    
    it "returns us zones if configuration says to" do
      Aspera::Config::Localization.stub_chain(:load_settings, :us_time_zones_only).and_return(true)
      App.time_zones.map(&:first).should == ActiveSupport::TimeZone.us_zones
    end
    
    it "returns all zones if configuration says to" do
      Aspera::Config::Localization.stub_chain(:load_settings, :us_time_zones_only).and_return(false)
      App.time_zones.map(&:first).should == ActiveSupport::TimeZone.all
    end
    
  end
  
  describe 'text helpers' do
    it "pluralize" do
      App.pluralize(nil, 'foo').should == "0 foos"
      App.pluralize(0, 'foo').should == "0 foos"
      App.pluralize(1, 'foo').should == "1 foo"
      App.pluralize(2, 'foo').should == "2 foos"
    end
  end
  
end