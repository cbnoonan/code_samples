require 'spec_helper'

describe NodeApi::Client do
  let(:client) { NodeApi::Client.new("lur", :username => 'un', :password => 'pw') }
  let(:site) { client.rest_client_site }
  
  describe '.initialize' do
    
    it "sets url" do
      client.url.should == 'lur'
    end
    
    it "sets username" do
      client.username.should == 'un'
    end
    
    it "sets password" do
      client.password.should == 'pw'
    end
    
    it "raises error on unknown option" do
      expect { NodeApi::Client.new('url', :foo => 'bar') }.to raise_error(Aspera::Error::InvalidOptionError)
    end
    
  end
  
  describe '#rest_client_site' do
    
    it "sets url" do
      site.url.should == 'lur'
    end
    
    it "sets user" do
      site.user.should == 'un'
    end
    
    it "sets password" do
      site.password.should == 'pw'
    end
  end
  
  describe '#browse' do

    it "success" do
      pending 'revert of specifying a count when the node api has a default count'
      payload = {:path => 'path'}.to_json
      resource = mock('resource')
      resource.should_receive(:post).with(payload).and_return('[ "http_response" ]')
      site.should_receive(:[]).with('files/browse').and_return(resource)
      response = client.browse(:path)
      response.http_response.should == '[ "http_response" ]'
    end

    it "exception" do
      exception = RuntimeError.new
      site.should_receive(:[]).with('files/browse').and_raise(exception)
      Aspera::Error.should_receive(:message).with(exception, :log_to_database => true).and_return("Internal error.")
      response = client.browse(:path)
      response.user_message.should =~ /Internal error\./
    end
  end

  describe '#create_directory' do

    it "success" do
      payload = { :paths => [ { :path => 'dir', :type => 'directory' } ] }.to_json
      resource = mock('resource')
      resource.should_receive(:post).with(payload).and_return('[ "http_response" ]')
      site.should_receive(:[]).with('files/create').and_return(resource)
      response = client.create_directory('dir')
      response.http_response.should == '[ "http_response" ]'
    end

    it "exception" do
      exception = RuntimeError.new
      site.should_receive(:[]).with('files/create').and_raise(exception)
      Aspera::Error.should_receive(:message).with(exception, :log_to_database => true).and_return("Internal error.")
      response = client.create_directory([ 'files' ])
      response.user_message.should =~ /Internal error\./
    end

  end
  
  describe '#create_file' do
  
    it "success" do
      payload = { :paths => [ {
        :path => 'my_file', :type => 'file', :contents => Base64.encode64('foo')
      } ] }.to_json
      resource = mock('resource')
      resource.should_receive(:post).with(payload).and_return('[ "http_response" ]')
      site.should_receive(:[]).with('files/create').and_return(resource)
      response = client.create_file('my_file', 'foo')
      response.http_response.should == '[ "http_response" ]'
    end

    it "exception" do
      exception = RuntimeError.new
      site.should_receive(:[]).with('files/create').and_raise(exception)
      Aspera::Error.should_receive(:message).with(exception, :log_to_database => true).and_return("Internal error.")
      response = client.create_file('my_file', 'foo')
      response.user_message.should =~ /Internal error\./
    end
    
  end  

  describe '#delete' do

    it "success" do
      payload = { :paths => [ { :path => 'file' } ] }.to_json
      resource = mock('resource')
      resource.should_receive(:post).with(payload).and_return('[ "http_response" ]')
      site.should_receive(:[]).with('files/delete').and_return resource
      response = client.delete [ 'file' ]
      response.http_response.should == '[ "http_response" ]'
    end

    it "exception" do
      exception = RuntimeError.new
      site.should_receive(:[]).with('files/delete').and_raise(exception)
      Aspera::Error.should_receive(:message).with(exception, :log_to_database => true).and_return("Internal error.")
      response = client.delete([ 'files' ])
      response.user_message.should =~ /Internal error\./
    end

  end

  describe '#download' do

    it "success" do
      payload = {
        "transfer_requests"=>[
          {
            "transfer_request"=>{
              "paths"=>[{"source"=>"file"}]
            }
          }
        ]
      }.to_json
      resource = mock('resource')
      resource.should_receive(:post).with(payload).and_return('[ "http_response" ]')
      site.should_receive(:[]).with('files/download_setup').and_return resource
      response = client.download ['file']
      response.http_response.should == '[ "http_response" ]'
    end

    it "exception" do
      exception = RuntimeError.new
      site.should_receive(:[]).with('files/download_setup').and_raise(exception)
      Aspera::Error.should_receive(:message).with(exception, :log_to_database => true).and_return("Internal error.")
      response = client.download ['file']
      response.user_message.should =~ /Internal error\./
    end

  end

  describe '#upload' do

    it "success" do
      payload = {
        "transfer_requests"=>[
          {
            "transfer_request"=>{
              "paths"=>[{"destination"=>"directory"}]
            }
          }
        ]
      }.to_json
      resource = mock('resource')
      resource.should_receive(:post).with(payload).and_return('[ "http_response" ]')
      site.should_receive(:[]).with('files/upload_setup').and_return resource
      response = client.upload 'directory'
      response.http_response.should == '[ "http_response" ]'
    end

    it "exception" do
      exception = RuntimeError.new
      site.should_receive(:[]).with('files/upload_setup').and_raise(exception)
      Aspera::Error.should_receive(:message).with(exception, :log_to_database => true).and_return("Internal error.")
      response = client.upload 'directory'
      response.user_message.should =~ /Internal error\./
    end

  end

end
