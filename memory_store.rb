require 'set'
class Solecist
  class MemoryStore
    def initialize
      @data = {}
    end
    def write key, data, view_version, metadata, time
      @data[key] ||= SortedSet.new
      @data[key] << [time, view_version, data, metadata]
    end
    def read key, view_version
      @data[key].to_a rescue 'TODO/WTF'
      @data[key].to_a.map do |(time, source_view_version, data, metadata)|
        { view_version: source_view_version, data: data, timestamp: time,
          metadata: metadata }
      end
    end
    def keys
      @data.keys
    end
  end
end

