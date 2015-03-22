require 'set'

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
      next if field.to_sym == :VERSION
      current_data = reference_data.merge data
      # hash means transformation
      if value.is_a?(Hash)
        dir_values = value[direction]
        target_field = dir_values[:target] || field
        sources_fields = dir_values[:source]
        transformer = dir_values[:transformer]
        new_value = transformer.call(*sources_fields.map{|f|current_data[f.to_sym]})
        new_data[target_field] = new_value
      # if we are going up or down, inherit means copy
      elsif value.to_sym == :INHERIT
        new_data[field] = current_data[field]
      # if we are going up new means nil out
      elsif value.to_sym == :NEW && direction == :UP
        new_data[field] = nil
      # if we are going down new means copy
      elsif value.to_sym == :NEW && direction == :DOWN
        new_data[field] = current_data[field]
      end
    end
    return new_data
  end
end

# TODO: back view collection w/ store ?
class ViewCollection
  def initialize
    @views = SortedSet.new
  end
  def create_or_retrieve schema
    # if it's a hash than it's a schema
    if schema.is_a?(Hash)
      view = View.new schema
      add(view) || self[view.version]
    # if it's not a hash than it's a schema version
    else
      self[schema]
    end
  end
  def add view
    unless @views.to_a.map{|ver,_|ver}.include? view.version
      @views << [view.version, view]
      return view
    end
    false
  end
  def latest
    @views.to_a.last.last
  end
  def to_a
    @views.to_a
  end
  def [] k
    Hash[self.to_a][k]
  end
end

