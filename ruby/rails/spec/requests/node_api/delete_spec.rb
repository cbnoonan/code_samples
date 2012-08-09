require 'spec_helper'

describe '/files/delete' do
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

  context 'when deleting multiple entries' do
    before do
      write_file 'foo.d/bar.f', ''
      write_file 'foo.d/baz.d/rmrfme.f', ''
      write_file 'foo.d/quux.f', ''
    end
    let(:request_body) { %q< { "paths": [ { "path": "/foo.d/bar.f" }, { "path": "/foo.d/baz.d" } ] } > }
    before { post node_api_files_delete_path, request_body }
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
          it { subject.assert_valid_keys %w[ path ] }
          its(['path']) { should == '/foo.d/bar.f' }
        end
        describe 'second path' do
          define_method(:subject) { super().second }
          it { subject.assert_valid_keys %w[ path ] }
          its(['path']) { should == '/foo.d/baz.d' }
        end
      end
    end
    describe 'filesystem' do
      it do
        check_file_presence %w[ foo.d/bar.f ], false
        check_directory_presence %w[ foo.d/baz.d ], false
        check_file_presence %w[ foo.d/quux.f ], true
      end
    end
  end

end
