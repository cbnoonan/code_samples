require 'spec_helper'

describe '/files/create' do
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

  context 'when creating a directory' do
    let(:request_body) { %q< { "paths": [ { "path": "/foo.d", "type": "directory" } ] } > }
    before { post node_api_files_create_path, request_body }
    describe 'response' do
      subject { last_response }
      its(:status) { should be(200) }
      its(:content_type) { should == 'application/json; charset=utf-8' }
    end
    describe 'response body' do
      subject { JSON.parse last_response.body }
      it { subject.assert_valid_keys %w[ paths ] }
      describe 'paths' do
        define_method(:subject) { super()['paths'] }
        it { should have(1).items }
        describe 'first path' do
          define_method(:subject) { super().first }
          it { subject.assert_valid_keys %w[ path type ] }
          its(['path']) { should == '/foo.d' }
          its(['type']) { should == 'directory' }
        end
      end
    end
    describe 'filesystem' do
      it { check_directory_presence %w[ foo.d ], true }
    end
  end

  context 'when creating multiple directories' do
    before { create_dir 'bar.d' }
    let(:request_body) do
      <<-EOJSON
        {
          "paths": [
            { "path": "/foo.d", "type": "directory" },
            { "path": "/bar.d/baz.d", "type": "directory" }
           ]
        }
      EOJSON
    end
    before { post node_api_files_create_path, request_body }
    describe 'response' do
      subject { last_response }
      its(:status) { should be(200) }
      its(:content_type) { should == 'application/json; charset=utf-8' }
    end
    describe 'response body' do
      subject { JSON.parse last_response.body }
      it { subject.assert_valid_keys %w[ paths ] }
      describe 'paths' do
        define_method(:subject) { super()['paths'] }
        it { should have(2).items }
        describe 'first path' do
          define_method(:subject) { super().first }
          it { subject.assert_valid_keys %w[ path type ] }
          its(['path']) { should == '/foo.d' }
          its(['type']) { should == 'directory' }
        end
        describe 'second path' do
          define_method(:subject) { super().second }
          it { subject.assert_valid_keys %w[ path type ] }
          its(['path']) { should == '/bar.d/baz.d' }
          its(['type']) { should == 'directory' }
        end
      end
    end
    describe 'filesystem' do
      it { check_directory_presence %w[ foo.d bar.d/baz.d ], true }
    end
  end

  context 'when the parent directory does not exist' do
    let(:request_body) { %q< { "paths": [ { "path": "/foo.d/bar.d", "type": "directory" } ] } > }
    before { post node_api_files_create_path, request_body }
    describe 'response' do
      subject { last_response }
      its(:status) { pending; should be(200) }
      its(:content_type) { should == 'application/json; charset=utf-8' }
    end
    describe 'response body' do
      subject { JSON.parse last_response.body }
      it { subject.assert_valid_keys %w[ paths ] }
      describe 'paths' do
        define_method(:subject) { super()['paths'] }
        it { should have(1).items }
        describe 'first path' do
          define_method(:subject) { super().first }
          its(['path']) { should == '/foo.d/bar.d' }
          its(['type']) { should == 'directory' }
          describe 'error' do
            define_method(:subject) { super()['error'] }
            its(['code']) { should be_an(Integer) }
            its(['user_message']) { should be_a(String) }
          end
        end
      end
    end
    describe 'filesystem' do
      it { check_directory_presence %w[ foo.d/bar.d ], false }
    end
  end

end
