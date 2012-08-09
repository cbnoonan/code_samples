# Methods for controllers displaying actions.  Handles:
#
# * pagination
# * loading more results
# * searching
# * sorting
#
# Subclasses must implement a #collection() method which usually returns an
# ActiveRecord association on the Action class.
#
#   class MyActionsController < Admin::BaseController
#     include Admin::ActionsControllerModule
#     helper Admin::ActionsHelper
#   
#     private
# 
#     def options_for_actions
#       {
#         :collection_scope => current_user.model.actions,
#         :feed_type => :all_activity,
#       }
#     end
#   
#   end
# 
module Admin::ActionsControllerModule 
    
  def index
    @feed_type = options[:feed_type]
    @title = options[:title]
    super
    render 'admin/actions/index' if !request.xhr?
  end

  private  

  def options_for_load_more
    {
      :collection => actions,
      :collection_name => 'actions',
      :load_more_partial => 'admin/actions/action',
    }
  end

  def actions
    @show_search = show_search?
    resolve_date_time_params
    scope = options[:collection_scope]
    if params[:events].present?
      @event_type_names = params[:events].split(",") & EventTypesController::EVENTS.keys
      @events = @event_type_names.map { |event| {:id => event, :name => event} }
      scope = scope.where(:event_type_name => @event_type_names)
    end
    if @dt_params[:from_date].present?
      @from_datetime = from_datetime
      if @from_datetime
        scope = scope.where("event_at >= ?", @from_datetime) if @from_datetime
      else
        flash.now[:error] = "Invalid 'From' date or time"
      end
    end
    if @dt_params[:to_date].present? 
      @to_datetime = to_datetime
      if @to_datetime
        scope = scope.where("event_at <= ?", @to_datetime) 
      else
        flash.now[:error] = "Invalid 'To' date or time"
      end
    end
    @options = nil # Footnotes sees @options as an assigned instance variable and evaluates its contents to display in the view.
    scope.order("event_at desc")
  end
  
  def from_datetime
    Time.zone.parse("#{@dt_params[:from_date]} #{@dt_params[:from_time]}")
  rescue ArgumentError => e
    nil
  end
  
  def to_datetime
    Time.zone.parse("#{@dt_params[:to_date]} #{@dt_params[:to_time]}") 
  rescue ArgumentError => e
    nil
  end
  
  def resolve_date_time_params
    @dt_params = Hash.new.tap do |hash|
      [:from_date, :from_time, :to_date, :to_time].each do |param|
        hash[param] = params[param]
      end
    end

    if @dt_params[:from_date].present? && @dt_params[:from_time].blank?
      @dt_params[:from_time] = '00:00'
    end
    
    if @dt_params[:from_time].present? && @dt_params[:from_date].blank?
      @dt_params[:from_date] = Time.zone.today
    end
    
    if @dt_params[:to_date].present? && @dt_params[:to_time].blank?
      @dt_params[:to_time] = '23:59:59'
    end

    if @dt_params[:to_time].present? && @dt_params[:to_date].blank?
      @dt_params[:to_date] = Time.zone.today
    end
  end

  def options
    @options ||= options_for_actions
  end
  
  def show_search?
    [:from_date, :from_time, :to_date, :to_time, :events].any? { |param| params[param].present? }
  end
end