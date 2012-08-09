class NodeApi::Response::Space < NodeApi::Response::Base

  def schema
    return nil
    
    
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
                error_schema[:keys][0].merge('path' => {:type => String}),
                {
                  'path' => {:type => String},
                  'bytes_total' => {:type => Integer, :optional => true},
                  'bytes_free' => {:type => Integer, :optional => true},
                  'percent_free' => {:type => Numeric, :optional => true},
                  'unknown' => {:type => Boolean, :optional => true}
                }
              ]
            }
          }
        }
      ]
    }
  end


end