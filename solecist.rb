# GOAL
# keep key/value pair
# so that i can view them at any point in history
# so that they can be filtered by arbitrary values
# so that any version of my writer can read and write


# client will define a set of views
# views form a chain
# each link in the view chain describes how it's
#  fields relate to the view before it
# reads will normalize each data slice to client's view
# we will call the arbitrary values which an entity's

# TODO: use better implimentation of sorted set
require_relative 'memory_store'
require_relative 'redis_store'
require_relative 'munger'
require_relative 'view'

class Solecist
  class MissingView < Exception; end;
  def initialize store, view_collection=ViewCollection.new
    @store = store
    @view_collection = view_collection
    @munger = Munger.new @view_collection
  end
  def write entity_key, view_schema, data, meta=nil, time=nil
    time ||= Time.now.to_f
    meta ||= {}
    view = @view_collection.create_or_retrieve(view_schema)
    @store.write entity_key, data, view.version, meta, time
    return { time: time, view_version: view.version }
  end
  def read entity_key, view_schema, meta=nil, time=nil
    time ||= Time.now.to_f
    meta ||= {}
    view = @view_collection.create_or_retrieve(view_schema)
    view ||= @view_collection.latest
    if view.nil?
      raise MissingView, "Missing view: #{view_schema}"
    end
    slices = @store.read entity_key, view.version
    return nil if slices.empty?
    time_filtered_slices = TimeFilter.filter slices, time
    meta_filtered_slices = MetaFilter.filter time_filtered_slices, meta
    @munger.munge meta_filtered_slices, view
  end
end

class TimeFilter
  def self.filter slices, time
    slices.select{|s| s[:timestamp] <= time}
  end
end

class MetaFilter
  def self.filter slices, meta_conditions
    slices.select do |slice|
      meta_conditions.to_a.all? do |(key, value)|
        slice[:metadata][key] == value
      end
    end
  end
end

