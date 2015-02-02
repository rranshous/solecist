class Munger
  def initialize view_collection
    @views = view_collection
  end
  def munge slices, target_view

    # munge them all to the highest view and
    # than munge the last view down to the target

    # munge the slices up to the highest view we have
    top_view = @views.to_a.last.last
    top_view_data = _munge(slices, top_view)

    # munge that data to the target view
    target_view_data = _munge([{ view_version: top_view.version,
                                 data: top_view_data }],
                             target_view)

    return target_view_data
  end
  def _munge slices, target_view

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
      if direction == :UP
        start_version = slice_view_version+1
        end_version = target_view.version
      elsif direction == :DOWN
        start_version = target_view.version+1
        end_version = slice_view_version
      end
      munge_views = views.select do |view_version, _|
        view_version <= end_version && view_version >= start_version
      end

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

