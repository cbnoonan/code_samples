require 'spec_helper'

describe '/files/rename' do
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

  context 'when renaming multiple files' do
    before do
      write_file 'foo.d/aaa.f', ''
      write_file 'bar.d/bbb.f', ''
      create_dir 'baz.d/quux.d'
    end
    let :request_body do
      #{ "path": "/foo.d", "source": "aaa.f", "destination": "/baz.d/AAA2.f" },
      <<-EOJSON
        {
          "paths": [
            { "path": "/foo.d", "source": "aaa.f", "destination": "AAA2.f" },
            { "path": "/bar.d", "source": "bbb.f", "destination": "BBB2.f" },
            { "path": "/baz.d", "source": "quux.d", "destination": "QUUX2.d" }
          ]
        }
      EOJSON
    end
    before { post node_api_files_rename_path, request_body }
    describe 'response' do
      subject { last_response }
      its(:status) { should be(200) }
      its(:content_type) { should == 'application/json; charset=utf-8' }
    end
    describe 'response body' do
      subject { JSON.parse last_response.body }
      describe 'paths' do
        define_method(:subject) { super()['paths'] }
        it { should have(3).items }
        describe 'first path' do
          define_method(:subject) { super().first }
          it { subject.assert_valid_keys %w[ path source destination ] }
          its(['path']) { should == '/foo.d' }
          its(['source']) { should == 'aaa.f' }
          #its(['destination']) { should == '/baz.d/AAA2.f' }
          its(['destination']) { should == 'AAA2.f' }
        end
        describe 'second path' do
          define_method(:subject) { super().second }
          it { subject.assert_valid_keys %w[ path source destination ] }
          its(['path']) { should == '/bar.d' }
          its(['source']) { should == 'bbb.f' }
          its(['destination']) { should == 'BBB2.f' }
        end
        describe 'third path' do
          define_method(:subject) { super().third }
          it { subject.assert_valid_keys %w[ path source destination ] }
          its(['path']) { should == '/baz.d' }
          its(['source']) { should == 'quux.d' }
          its(['destination']) { should == 'QUUX2.d' }
        end
      end
    end
    describe 'filesystem' do
      it do
        check_file_presence %w[ foo.d/aaa.f ], false
        check_file_presence %w[ bar.d/bbb.f ], false
        check_directory_presence %w[ baz.d/quux.d ], false

        check_file_presence %w[ bar.d/BBB2.f ], true
        #check_file_presence %w[ baz.d/AAA2.f ], true
        check_file_presence %w[ foo.d/AAA2.f ], true
        check_directory_presence %w[ baz.d/QUUX2.d ], true

        check_directory_presence %w[ foo.d ], true
      end
    end
  end

  context 'when not all renames are successful' do
    before do
      write_file 'foo.d/aaa.f', ''
      create_dir 'bar.d/bbb.d'
    end
    let :request_body do
      <<-EOJSON
        {
          "paths": [
            { "path": "/foo.d", "source": "aaa.f", "destination": "AAA2.f" },
            { "path": "/bar.d", "source": "bbb.d", "destination": "invalid/BBB2.d" }
          ]
        }
      EOJSON
    end
    before { post node_api_files_rename_path, request_body }
    describe 'response' do
      subject { last_response }
      its(:status) { should be(200) }
      its(:content_type) { should == 'application/json; charset=utf-8' }
    end
    describe 'response body' do
      subject { JSON.parse last_response.body }
      describe 'paths' do
        define_method(:subject) { super()['paths'] }
        it { should have(2).items }
        describe 'first path' do
          define_method(:subject) { super().first }
          it { subject.assert_valid_keys %w[ path source destination ] }
          its(['path']) { should == '/foo.d' }
          its(['source']) { should == 'aaa.f' }
          its(['destination']) { should == 'AAA2.f' }
        end
        describe 'second path' do
          define_method(:subject) { super().second }
          it { subject.assert_valid_keys %w[ path source destination error ] }
          its(['path']) { should == '/bar.d' }
          its(['source']) { should == 'bbb.d' }
          its(['destination']) { should == 'invalid/BBB2.d' }
          describe 'error' do
            define_method(:subject) { super()['error'] }
            it { subject.assert_valid_keys %w[ code user_message internal_message ] }
            its(['code']) { should be_an(Integer) }
            its(['user_message']) { should be_a(String) }
          end
        end
      end
    end
    describe 'filesystem' do
      it do
        check_file_presence %w[ foo.d/aaa.f ], false
        check_directory_presence %w[ bar.d/bbb.d ], true

        check_file_presence %w[ foo.d/AAA2.f ], true
        check_directory_presence %w[ bar.d/invalid/BBB2.d ], false
      end
    end
  end

end
