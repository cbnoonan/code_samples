require 'spec_helper'

describe '/files/browse' do
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

  shared_context 'case sensitivity' do
    before do
      write_file 'foo.d/bbb.f', ''
      write_file 'foo.d/aaa.d/bar.f', ''
      write_file 'foo.d/Animated.GIF', ''
      write_file 'foo.d/ccc.f', ''
    end
    before { post node_api_files_browse_path, request_body }
    describe 'response' do
      subject { last_response }
      its(:status) { should be(200) }
      its(:content_type) { should == 'application/json; charset=utf-8' }
    end
  end

  shared_context 'case sensitive' do
    include_context 'case sensitivity'
    describe 'response body' do
      subject { JSON.parse last_response.body }
      it { subject.assert_valid_keys %w[ items item_count total_count parameters ] }
      describe 'items' do
        define_method(:subject) { super()['items'] }
        it { should have(0).items }
      end
      describe 'parameters' do
        define_method(:subject) { super()['parameters'] }
        it { subject.assert_valid_keys %w[ path skip count filters case_sensitive ] }
      end
    end
  end

  shared_context 'case insensitive' do
    include_context 'case sensitivity'
    describe 'response body' do
      subject { JSON.parse last_response.body }
      it { subject.assert_valid_keys %w[ items item_count total_count parameters ] }
      describe 'items' do
        define_method(:subject) { super()['items'] }
        it { should have(1).items }
        describe 'first item' do
          define_method(:subject) { super().first }
          it { subject.assert_valid_keys %w[ path size mtime type ] }
          its(['path']) { should == '/foo.d/Animated.GIF' }
        end
      end
      describe 'parameters' do
        define_method(:subject) { super()['parameters'] }
        it { subject.assert_valid_keys %w[ path skip count filters case_sensitive ] }
      end
    end
  end

  context 'when filtering with case sensitivity' do
    let(:request_body) { %q< { "path": "/foo.d", "filters": { "basenames": [ "*.gif" ] }, "case_sensitive": true } > }
    include_context 'case sensitive'
  end

  context 'when filtering with case insensitivity' do
    let(:request_body) { %q< { "path": "/foo.d", "filters": { "basenames": [ "*.gif" ] }, "case_sensitive": false } > }
    include_context 'case insensitive'
  end

  context 'when filtering without specifying case sensitivity' do
    let(:request_body) { %q< { "path": "/foo.d", "filters": { "basenames": [ "*.gif" ] } } > }
    include_context 'case insensitive'
  end

end
