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

  context 'when sorting by type' do
    before do
      (0...10).to_a.shuffle.each do |i|
        write_file 'file%03d' % i, ''
        create_dir 'dir%03d' % i
      end
    end
    let(:request_body) { %q< { "path": "/", "sort": "type" } > }
    before { post node_api_files_browse_path, request_body }
    describe 'response' do
      subject { last_response }
      its(:status) { should be(200) }
      its(:content_type) { should == 'application/json; charset=utf-8' }
    end
    describe 'response body' do
      subject { JSON.parse last_response.body }
      it { subject.assert_valid_keys %w[ items item_count total_count parameters ] }
      describe 'items' do
        define_method(:subject) { super()['items'] }
        it { should have(20).items }
        it 'is sorted by type and path' do
          10.times {|i| subject[i]['path'].should == '/dir%03d' % i }
          10.times {|i| subject[10 + i]['path'].should == '/file%03d' % i }
        end
      end
    end
  end

  context 'when sorting by path' do
    before do
      (0...10).to_a.shuffle.each do |i|
        write_file '%03d_file' % i, ''
        create_dir '%03d_dir' % i
      end
    end
    let(:request_body) { %q< { "path": "/", "sort": "path" } > }
    before { post node_api_files_browse_path, request_body }
    describe 'response' do
      subject { last_response }
      its(:status) { should be(200) }
      its(:content_type) { should == 'application/json; charset=utf-8' }
    end
    describe 'response body' do
      subject { JSON.parse last_response.body }
      it { subject.assert_valid_keys %w[ items item_count total_count parameters ] }
      describe 'items' do
        define_method(:subject) { super()['items'] }
        it { should have(20).items }
        it 'is sorted by type and path' do
          10.times do |i|
            subject[2 * i    ]['path'].should == '/%03d_dir' % i
            subject[2 * i + 1]['path'].should == '/%03d_file' % i
          end
        end
      end
    end
  end

  context 'when filtering in the docroot' do
    before do
      write_file 'bbb.f', ''
      write_file 'aaa.d/foo.f', ''
      write_file 'animated.gif', ''
      write_file 'ccc.f', ''
    end
    let(:request_body) { %q< { "path": "/", "filters": { "basenames": [ "*.gif" ] } } > }
    before { post node_api_files_browse_path, request_body }
    describe 'response' do
      subject { last_response }
      its(:status) { should be(200) }
      its(:content_type) { should == 'application/json; charset=utf-8' }
    end
    describe 'response body' do
      subject { JSON.parse last_response.body }
      it { subject.assert_valid_keys %w[ items item_count total_count parameters ] }
      describe 'items' do
        define_method(:subject) { super()['items'] }
        it { should have(1).item }
        describe 'first item' do
          define_method(:subject) { super().first }
          it { subject.assert_valid_keys %w[ path size mtime type ] }
          its(['path']) { should == '/animated.gif' }
        end
      end
    end
  end

  context 'when filtering in a directory' do
    before do
      write_file 'foo.d/bbb.f', ''
      write_file 'foo.d/aaa.d/bar.f', ''
      write_file 'foo.d/animated.gif', ''
      write_file 'foo.d/ccc.f', ''
    end
    let(:request_body) { %q< { "path": "/foo.d", "filters": { "basenames": [ "*.gif" ] } } > }
    before { post node_api_files_browse_path, request_body }
    describe 'response' do
      subject { last_response }
      its(:status) { should be(200) }
      its(:content_type) { should == 'application/json; charset=utf-8' }
    end
    describe 'response body' do
      subject { JSON.parse last_response.body }
      it { subject.assert_valid_keys %w[ items item_count total_count parameters ] }
      describe 'items' do
        define_method(:subject) { super()['items'] }
        it { should have(1).items }
        describe 'first item' do
          define_method(:subject) { super().first }
          it { subject.assert_valid_keys %w[ path size mtime type ] }
          its(['path']) { should == '/foo.d/animated.gif' }
        end
      end
    end
  end

end
