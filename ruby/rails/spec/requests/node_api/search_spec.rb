require 'spec_helper'

describe '/files/search' do
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

  context 'given an empty directory' do
    before { create_dir 'foo' }
    let(:request_body) { %q< { "path": "/foo" } > }
    before { post node_api_files_search_path, request_body }
    describe 'response' do
      subject { last_response }
      its(:status) { should be(200) }
      its(:content_type) { should == 'application/json; charset=utf-8' }
    end
    describe 'response body' do
      subject { JSON.parse last_response.body }
      it { subject.assert_valid_keys %w[ items total_count parameters ] }
      describe 'items' do
        define_method(:subject) { super()['items'] }
        it { should have(0).items }
      end
    end
  end

  context 'given a non-empty docroot' do
    before do
      write_fixed_size_file 'aaa/foo.f', 88
      write_fixed_size_file 'aaa/bar.d/baz.f', 99
    end
    let(:request_body) { %q< { "path": "/" } > }
    before { post node_api_files_search_path, request_body }
    describe 'response' do
      subject { last_response }
      its(:status) { should be(200) }
      its(:content_type) { should == 'application/json; charset=utf-8' }
    end
    describe 'response body' do
      subject { JSON.parse last_response.body }
      it { subject.assert_valid_keys %w[ items total_count parameters ] }
      describe 'items' do
        define_method(:subject) { super()['items'].sort_by {|item| item['path'] } }
        it { should have(4).items }
        describe 'first item' do
          define_method(:subject) { super().first }
          it { subject.assert_valid_keys %w[ path size mtime type ] }
          its(['path']) { should == '/aaa' }
          its(['type']) { should == 'directory' }
          its(['size']) { should be_an(Integer) }
          it { expect { DateTime.parse subject['mtime'] }.not_to raise_exception }
        end
        describe 'second item' do
          define_method(:subject) { super().second }
          it { subject.assert_valid_keys %w[ path size mtime type ] }
          its(['path']) { should == '/aaa/bar.d' }
          its(['type']) { should == 'directory' }
          its(['size']) { should be_an(Integer) }
          it { expect { DateTime.parse subject['mtime'] }.not_to raise_exception }
        end
        describe 'third item' do
          define_method(:subject) { super().third }
          it { subject.assert_valid_keys %w[ path size mtime type ] }
          its(['path']) { should == '/aaa/bar.d/baz.f' }
          its(['type']) { should == 'file' }
          its(['size']) { should be(99) }
          it { expect { DateTime.parse subject['mtime'] }.not_to raise_exception }
        end
        describe 'fourth item' do
          define_method(:subject) { super().fourth }
          it { subject.assert_valid_keys %w[ path size mtime type ] }
          its(['path']) { should == '/aaa/foo.f' }
          its(['type']) { should == 'file' }
          its(['size']) { should be(88) }
          it { expect { DateTime.parse subject['mtime'] }.not_to raise_exception }
        end
      end
    end
  end

  context 'given an empty directory and a basename filter' do
    before { create_dir 'foo' }
    let(:request_body) { %q< { "path": "/foo", "filters": { "basenames": [ "*.gif" ] } } > }
    before { post node_api_files_search_path, request_body }
    describe 'response' do
      subject { last_response }
      its(:status) { should be(200) }
      its(:content_type) { should == 'application/json; charset=utf-8' }
    end
    describe 'response body' do
      subject { JSON.parse last_response.body }
      it { subject.assert_valid_keys %w[ items total_count parameters ] }
      describe 'items' do
        define_method(:subject) { super()['items'] }
        it { should have(0).items }
      end
    end
  end

  context 'given a non-empty directory and a basename filter' do
    before do
      write_fixed_size_file 'aaa/foo.f', 88
      write_fixed_size_file 'aaa/bar.d/baz.f', 99
    end
    let(:request_body) { %q< { "path": "/aaa", "filters": { "basenames": [ "*ba*" ] } } > }
    before { post node_api_files_search_path, request_body }
    describe 'response' do
      subject { last_response }
      its(:status) { should be(200) }
      its(:content_type) { should == 'application/json; charset=utf-8' }
    end
    describe 'response body' do
      subject { JSON.parse last_response.body }
      it { subject.assert_valid_keys %w[ items total_count parameters ] }
      describe 'items' do
        define_method(:subject) { super()['items'].sort_by {|item| item['path'] } }
        it { should have(2).items }
        describe 'first item' do
          define_method(:subject) { super().first }
          it { subject.assert_valid_keys %w[ path size mtime type ] }
          its(['path']) { should == '/aaa/bar.d' }
          its(['type']) { should == 'directory' }
          its(['size']) { should be_an(Integer) }
          it { expect { DateTime.parse subject['mtime'] }.not_to raise_exception }
        end
        describe 'second item' do
          define_method(:subject) { super().second }
          it { subject.assert_valid_keys %w[ path size mtime type ] }
          its(['path']) { should == '/aaa/bar.d/baz.f' }
          its(['type']) { should == 'file' }
          its(['size']) { should be(99) }
          it { expect { DateTime.parse subject['mtime'] }.not_to raise_exception }
        end
      end
    end
  end


end
