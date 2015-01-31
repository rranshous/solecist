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
require 'set'

class MemoryStore < Hash
  def initialize
    @data = {}
  end
  def write key, data, view_version
    @data[key] ||= SortedSet.new
    @data[key] << [Time.now.to_i, view_version, data]
  end
  def read key, view_version
    @data[key].to_a.map do |(_, source_view_version, data)|
      { view_version: source_view_version, data: data }
    end
  end
end

class Munger
  def initialize
    @views = SortedSet.new
  end
  def add_view view
    @views << [view.version, view]
  end
  def view_lookup
    Hash[@views.to_a]
  end
  def munge slices, target_view
    # go through each of the slices transforming their
    # data into the target view's version
    final_data = {}
    # walk slices from oldest to newest
    # TODO: guarentee order?
    slices.each do |slice|

      # better to do no work, skip to the end
      # TODO: this short circuit is ugly
      slice_view_version = slice[:view_version]
      if slice_view_version == target_view.version
        final_data.merge! slice[:data]
        next
      end

      # don't change the data passed to us
      slice_data = slice[:data].dup

      # sort the views we are going to walk through based on
      # whether we are transforming "up" or "down" the chain
      # they are already sorted for walking "up"
      direction = slice_view_version < target_view.version ? :UP : :DOWN
      views = @views.to_a.dup
      views.reverse! if direction == :DOWN

      # figure out as we walk the chain where we should start and
      # where we should stop our transformations
      t = [slice_view_version, target_view.version]
      start_version, end_version = direction == :UP ? t : t.reverse
      munge_views = views.select do |view_version, _|
        view_version <= end_version && view_version > start_version
      end

      # munge our slice data throuh each of the view transformations
      munge_views.each do |(_,munge_view)|
        slice_data = munge_view.transform direction, slice_data
      end

      # merge this slice's munged data into the final entities data
      final_data.merge! slice_data
    end
    # we should have now gone through all the slices
    # merging their data (transformed into the target view's format)
    # into the final data. fin
    return final_data
  end
end

class View
  def initialize schema
    @schema = schema
  end
  def version
    @schema[:VERSION]
  end
  def transform direction, data
    new_data = {}
    @schema.each do |field, value|
      next if field == :VERSION
      if value.is_a?(Hash)
        dir_values = value[direction]
        target_field = dir_values[:target]
        sources_fields = dir_values[:source]
        transformer = dir_values[:transformer]
        new_value = transformer.call(*sources_fields.map{|f|data[f]})
        new_data[target_field] = new_value
      end
    end
    return new_data
  end
end

class Solecist
  def initialize store
    @store = store
    @munger = Munger.new
  end
  def write entity_key, view_schema, data
    view = View.new(view_schema)
    @munger.add_view view
    @store.write entity_key, data, view.version
  end
  def read entity_key, view_schema
    view = View.new(view_schema)
    slices = @store.read entity_key, view.version
    @munger.munge slices, view
  end
end
