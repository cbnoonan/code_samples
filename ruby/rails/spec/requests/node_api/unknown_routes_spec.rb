#require 'spec_helper'
#
#describe 'unknown route' do
#  include Rack::Test::Methods
#  before { Tasks::Init.init }
#
#  %w[
#    /node_api
#    /node_api/foo
#    /node_api/foo/bar
#  ].each do |route|
#
#    describe route do
#
#      before do
#        get route
#      end
#
#      it 'responds not found' do
#        last_response.should be_not_found
#      end
#
#    end
#
#  end
#
#end
