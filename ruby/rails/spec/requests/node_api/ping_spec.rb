require 'spec_helper'

# for rubymine debugging
# require_relative '../../spec_helper_node.rb'

describe '/ping' do
  include Rack::Test::Methods
  before { Tasks::Init.init }

  before do
    get node_api_ping_path
  end

  it 'succeeds' do
    # last_response.status.should be_(200)
    last_response.should be_ok
  end

  xit 'responds with json' do
    last_response.content_type.should == 'application/json; charset=utf-8'
  end

  ## rails
  #it 'returns status code 200' do
  #  get node_api_ping_path
  #  response.status.should be(200)
  #end
  #
  ## rails
  #it 'returns status code 200' do
  #  get node_api_ping_path
  #  assert_response :success
  #end
  #
  ## capybara
  #it 'returns status code 200' do
  #  visit node_api_ping_path
  #  page.status_code.should be(200)
  #end

  #it 'foos' do
  #  authorization = ActionController::HttpAuthentication::Basic.encode_credentials('apiuser', 'aspera')
  #  post node_api_ping_path, '{"path":"/"}',
  #      'HTTP_ACCEPT'        => 'application/json',
  #      'CONTENT_TYPE'       => 'application/json',
  #      'HTTP_AUTHORIZATION' => authorization
  #  assert_response :success
  #end

end
