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

  context 'given an empty docroot' do
    let(:request_body) { %q< { "path": "/" } > }
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
        it { should have(0).items }
      end
    end
  end

  context 'given a docroot with one file' do
    before { write_fixed_size_file 'foo.f', 88 }
    let(:request_body) { %q< { "path": "/" } > }
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
          its(['path']) { should == '/foo.f' }
          its(['type']) { should == 'file' }
          its(['size']) { should == 88 }
          it { expect { DateTime.parse subject['mtime'] }.not_to raise_exception }
        end
      end
    end
  end

  context 'given a docroot with one directory' do
    before { create_dir 'foo.d' }
    let(:request_body) { %q< { "path": "/" } > }
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
          its(['path']) { should == '/foo.d' }
          its(['type']) { should == 'directory' }
          its(['size']) { should == be_an(Integer) }
          it { expect { DateTime.parse subject['mtime'] }.not_to raise_exception }
        end
      end
    end
  end

  context 'given an empty directory' do
    before { create_dir 'foo' }
    let(:request_body) { %q< { "path": "/foo" } > }
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
        it { should have(0).items }
      end
    end
  end

  context 'given a directory with one file' do
    before { write_fixed_size_file 'foo/bar.f', 88 }
    let(:request_body) { %q< { "path": "/foo" } > }
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
          its(['path']) { should == '/foo/bar.f' }
          its(['type']) { should == 'file' }
          its(['size']) { should == 88 }
          it { expect { DateTime.parse subject['mtime'] }.not_to raise_exception }
        end
      end
    end
  end

  context 'given a directory with one directory' do
    before { create_dir 'foo/bar.d' }
    let(:request_body) { %q< { "path": "/foo" } > }
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
          its(['path']) { should == '/foo/bar.d' }
          its(['type']) { should == 'directory' }
          its(['size']) { should == be_an(Integer) }
          it { expect { DateTime.parse subject['mtime'] }.not_to raise_exception }
        end
      end
    end
  end

  context 'given a docroot with multiple items' do
    before do
      write_file 'bbb.f', ''
      write_file 'aaa.d/foo.f', ''
      write_file 'ccc.f', ''
    end
    let(:request_body) { %q< { "path": "/" } > }
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
        define_method(:subject) { super()['items'].sort_by {|item| File.basename item['path'] } }
        it { should have(3).items }
        it 'contains all the items' do
          items = subject
          items[0]['path'].should == '/aaa.d'
          items[1]['path'].should == '/bbb.f'
          items[2]['path'].should == '/ccc.f'
        end
      end
    end
  end

  context 'given a directory with multiple items' do
    before do
      write_file 'foo.d/bbb.f', ''
      write_file 'foo.d/aaa.d/bar.f', ''
      write_file 'foo.d/ccc.f', ''
    end
    let(:request_body) { %q< { "path": "/foo.d" } > }
    before { post node_api_files_browse_path, request_body }
    describe 'response' do
      define_method(:subject) { last_response }
      its(:status) { should be(200) }
      its(:content_type) { should == 'application/json; charset=utf-8' }
    end
    describe 'response body' do
      subject { JSON.parse last_response.body }
      it { subject.assert_valid_keys %w[ items item_count total_count parameters ] }
      describe 'items' do
        define_method(:subject)  { super()['items'].sort_by {|item| File.basename item['path'] } }
        it { should have(3).items }
        it 'contains all items' do
          items = subject
          items[0]['path'].should == '/foo.d/aaa.d'
          items[1]['path'].should == '/foo.d/bbb.f'
          items[2]['path'].should == '/foo.d/ccc.f'
        end
      end
    end
  end

end
