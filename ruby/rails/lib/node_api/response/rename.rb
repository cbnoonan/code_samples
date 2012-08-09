class NodeApi::Response::Rename < NodeApi::Response::Base

  include ::NodeApi::Response::PathMethods

  def schema
    {
      :type => Hash,
      :keys => [
        error_schema[:keys][0],
        {
          'paths' => {
            :type => Array,
            :of => {
              :type => Hash,
              :keys => [
                error_schema[:keys][0].merge({
                  'path' => {:type => String},
                  'source' => {:type => String},
                  'destination' => {:type => String},
                }),
                {
                  'path' => {:type => String},
                  'source' => {:type => String},
                  'destination' => {:type => String},
                }
              ]
            }
          }
        }
      ]
    }
  end
  
end