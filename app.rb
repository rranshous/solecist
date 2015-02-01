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
    @data[key].to_a rescue 'WTF'
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
    unless @views.to_a.map{|ver,_|ver}.include? view.version
      @views << [view.version, view]
    end
  end
  def view_lookup
    Hash[@views.to_a]
  end
  def munge slices, target_view

    # munge them all to the highest view and
    # than munge the last view down to the target

    # munge the slices up to the highest view we have
    @views.to_a rescue 'WTF'
    top_view = @views.to_a.last.last
    puts "TO HIGHEST"
    top_view_data = _munge(slices, top_view)
    puts "TOP VIEW DATA: #{top_view_data}"

    # munge that data to the target view
    puts "TO TARGET #{target_view.version}"
    target_view_data = _munge([{ view_version: top_view.version,
                                 data: top_view_data }],
                             target_view)
    puts "TARGET DATA: #{target_view_data}"

    return target_view_data
  end
  def _munge slices, target_view

    puts "MUNGE to #{target_view.version}"

    # go through each of the slices transforming their
    # data into the target view's version
    final_data = {}

    # walk slices from oldest to newest
    # TODO: guarentee order?
    slices.each do |slice|


      # better to do no work, skip to the end
      # TODO: this short circuit is ugly
      slice_view_version = slice[:view_version]
      puts " SLICE VIEW VERSION: #{slice_view_version}"
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
      puts " DIRECTION: #{direction}"

      # figure out as we walk the chain where we should start and
      # where we should stop our transformations
      if direction == :UP
        start_version = slice_view_version+1
        end_version = target_view.version
      elsif direction == :DOWN
        start_version = target_view.version+1
        end_version = slice_view_version
      end
      puts " START #{start_version} :: END #{end_version}"
      munge_views = views.select do |view_version, _|
        view_version <= end_version && view_version >= start_version
      end
      puts " MUNGE VIEWS: #{munge_views.map{|v|v.first}}"

      # munge our slice data throuh each of the view transformations
      munge_views.each do |(_,munge_view)|
        slice_data = munge_view.transform(direction, slice_data, final_data)
      end

      # merge this slice's munged data into the final entities data
      final_data.merge! slice_data
    end

    # filter the data down to the final view's schema
    filtered_final_data = target_view.filter final_data


    # we should have now gone through all the slices
    # merging their data (transformed into the target view's format)
    # into the final data. fin
    return filtered_final_data
  end
end

class View
  def initialize schema
    @schema = schema
  end
  def version
    @schema[:VERSION]
  end
  def filter data
    Hash[ data.to_a.select{|(k,_)| @schema.include?(k)} ]
  end
  def transform direction, data, reference_data
    # it seems i'll need to transform the reference data
    # up to my view so that i can reference it in terms i understand
    new_data = {}
    @schema.each do |field, value|
      next if field == :VERSION
      current_data = reference_data.merge data
      # if we are going up or down, inherit means copy
      if value == :INHERIT
        new_data[field] = current_data[field]
      # if we are going up new means nil out
      elsif value == :NEW && direction == :UP
        new_data[field] = nil
      # if we are going down new means copy
      elsif value == :NEW && direction == :DOWN
        new_data[field] = current_data[field]
      # hash means transformation
      elsif value.is_a?(Hash)
        dir_values = value[direction]
        target_field = dir_values[:target] || field
        sources_fields = dir_values[:source]
        transformer = dir_values[:transformer]
        new_value = transformer.call(*sources_fields.map{|f|current_data[f]})
        new_data[target_field] = new_value
      end
    end
    #require 'pry'; binding.pry
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
