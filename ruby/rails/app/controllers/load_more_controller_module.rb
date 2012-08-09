# To use:
#
#   Controller:
#     private
#     def options_for_load_more
#       { 
#         :collection => Delayed::Job.by_priority,
#
#         # default determined from controller name
#         :collection_name => 'delayed_jobs',
#
#         # default determined from collection
#         :load_more_partial => 'delayed_job',
#
#         # default is App.per_page
#         :per_page => 3,
#
#         # hash of paramaters to add to the more_link. 
#         # default is {}
#         :load_more_link_params => {:sort => "type"},
#       }
#     end
#
#   View:
#     - Add the class 'loads_more' to the DOM element that will receive more elements.
#     - Use the 'more_link' helper method after the '.loads_more' DOM element.
#
# If your controller wants to have this functionality in an action other than
# the #index action:
#
#   def other_action
#     configure_load_more
#     render "shared/load_more" if request.xhr?
#   end
#

module LoadMoreControllerModule
  attr_accessor :collection, :collection_name, :load_more_partial, :per_page, :load_more_link_params
  
  def index
    configure_load_more
    render "shared/load_more" if request.xhr?
  end
  
  def self.included(mod)
    mod.helper_method :collection, :load_more_partial, :load_more_link_params
  end
  
  private
  
  def configure_load_more(options = nil)
    options ||= options_for_load_more
    App.assign_attributes(self, options)
    
    page = params[:page] || 1
    self.collection = collection.paginate(:page => page, :per_page => (per_page || App.per_page))
    self.instance_variable_set("@#{collection_name || controller_underscore}".to_sym, collection)
  end
  
  def controller_underscore
    self.class.name.split("::").last.underscore.sub('_controller', '')
  end
  
end
