class NodeApi::Response::Create < NodeApi::Response::Base

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
                  # 'type' => {:type => String},
                }),
                {
                  'path' => {:type => String},
                  # 'type' => {:type => String},
                }
              ]
            }
          }
        }
      ]
    }
  end

end
