class NodeApi::Response::Browse < NodeApi::Response::Base
  
  def directory_items
    @directory_items ||= begin
      items = response_parsed['items']
      if items
        items.map do |item|
          DirectoryItem::Base.new_item(item)
        end
      else
        ErrorLog.log_error({
          :message => "#{self.class.name}: Invalid response from node",
          :description => http_response,
        })
        []
      end
    end
  end

  def schema
    { :type => Hash }
  end

  #def schema
  #  {
  #    :type => Hash,
  #    :keys => [
  #      error_schema[:keys][0],
  #      {
  #        'items' => {
  #          :type => Array,
  #          :of => {
  #            :type => Hash,
  #            :keys => [
  #              error_schema[:keys][0].merge({'path' => {:type => String}}),
  #              {
  #                'path' => {:type => String},
  #                'type' => {:type => String},
  #                'size' => {:type => Integer},
  #                'mtime' => {:type => Time, :optional => true},
  #              }
  #            ]
  #          }
  #        },
  #        'parameters' => {
  #          :type => Hash,
  #          :keys => [
  #            {
  #              # 'count' => {:type => Integer},
  #              # 'skip' => {:type => Integer},
  #              # 'sort' => {:type => String},
  #              # 'path' => {:type => String},
  #              # 'filters' => {
  #              #   :type => Hash,
  #              #   :keys => [
  #              #     {
  #              #       'basenames' => {:type => Array, :allow_nil => true},
  #              #       'size_min' => {:type => Integer, :allow_nil => true},
  #              #       'size_max' => {:type => Integer, :allow_nil => true},
  #              #       'mtime_min' => {:type => Time, :allow_nil => true},
  #              #       'mtime_max' => {:type => Time, :allow_nil => true},
  #              #     }
  #              #   ]
  #              # }
  #            }
  #          ]
  #        }
  #      }
  #    ]
  #  }
  #end

end
