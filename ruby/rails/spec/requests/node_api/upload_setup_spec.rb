require 'spec_helper'

describe '/files/upload_setup' do
  include Rack::Test::Methods
  before { Tasks::Init.init }

  include Aruba::Api
  before do
    FileUtils.rm_rf current_dir
    # ensure creation of tmp/aruba
    in_current_dir {}
    Rails.application.config.docroot = Rails.root.join current_dir
  end

  let(:api_user) { Factory :api_user }
  before { authorize api_user.username, api_user.password }

  before do
    header 'Accept', 'application/json'
    header 'Content-Type', 'application/json'
  end

  let(:response_json) { JSON.parse last_response.body }

  context 'simple request' do
    before { create_dir 'foo.d' }
    let :request_body do
      <<-EOJSON
        {
          "transfer_requests": [
            {
              "transfer_request" : {
                "paths": [ { "destination": "/foo.d" } ]
              }
            }
          ]
        }
      EOJSON
    end
    before { 
      NodeApi::Transfer.any_instance.stub(:upload_token).and_return("abc")
      post node_api_files_upload_setup_path, request_body 
    }
    describe 'the response' do
      subject { last_response }
      its(:status) { should be(200) }
      its(:content_type) { should == 'application/json; charset=utf-8' }
    end
    describe 'the response parsed' do
      subject { response_json }
      it { should have_key('transfer_specs') }
      it { should == {
          "transfer_specs"=>[
            {
              "transfer_spec"=>{
                "paths"=>[
                  { "destination"=>"/foo.d" },
                ], 
                "token"=>"abc", 
                "direction"=>"send",
                "remote_host"=>"example.org", 
                "remote_user"=>"asp1", 
                "ssh_port"=>22, 
                "fasp_port"=>33001
              },
            },
          ]
        }
      }
    end
  end

  context 'more complicated request' do
    before { create_dir 'foo.d' }
    let :request_body do
      {
        "transfer_requests" => [
          {
            "transfer_request" => {
              "destination_root" => "/destination/root",
              "paths"=> [ 
                { "destination" => "/foo.1" },
                { "destination" => "/foo.2" },
              ]
            },
            "arbitrary_property" => 13,
            "another_arbitrary_property" => { 'x' => 'y' },
          }
        ]
      }.to_json
    end
    before { 
      NodeApi::Transfer.any_instance.stub(:upload_token).and_return("abc")
      post node_api_files_upload_setup_path, request_body 
    }
    describe 'the response' do
      subject { last_response }
      its(:status) { should be(200) }
      its(:content_type) { should == 'application/json; charset=utf-8' }
    end
    describe 'the response parsed' do
      subject { response_json }
      it { should have_key('transfer_specs') }
      it { should == {
          "transfer_specs"=>[
            {
              "transfer_spec"=>{
                "destination_root"=>"/destination/root", 
                "paths"=>[{"destination"=>"/foo.1"}, {"destination"=>"/foo.2"}], 
                "token"=>"abc", 
                "direction"=>"send",
                "remote_host"=>"example.org", 
                "remote_user"=>"asp1", 
                "ssh_port"=>22, 
                "fasp_port"=>33001
              }, 
              "arbitrary_property"=>13, 
              "another_arbitrary_property"=>{"x"=>"y"}
            }
          ]
        }
      }
    end
  end
  

end
