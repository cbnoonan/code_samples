require 'spec_helper'

describe '/files/browse when unauthorized' do
  include Rack::Test::Methods
  before { Tasks::Init.init }
  subject { last_response }

  before do
    header 'Accept', 'application/json'
    header 'Content-Type', 'application/json'
    post node_api_files_browse_path, <<-EOJSON
      { "path": "/" }
    EOJSON
  end

  its(:status) { should be(401) }

end
