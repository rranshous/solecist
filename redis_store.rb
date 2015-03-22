require 'redis'
require 'json'

class Solecist
  class RedisStore
    def initialize
      @redis = Redis.new
    end
    def write key, data, view_version, metadata, time
      to_write = { data: data, view_version: view_version,
                   metadata: metadata, timestamp: time, key: key }
      @redis.zadd key_for(key), time, to_write.to_json
    end
    def read key, view_version
      raw_datas = @redis.zrange key_for(key), 0, -1
      datas = raw_datas.map { |d| symbolize_keys(JSON.load(d)) }
      datas
    end
    def keys
      @redis.keys("slices:*").map{|k| k[7..-1]}
    end
    private
    def key_for key
      "slices:#{key}"
    end
    def symbolize_keys(hash)
      return nil if hash.nil?
      hash.inject({}){|result, (key, value)|
        new_key = case key
                  when String then key.to_sym
                  else key
                  end
        new_value = case value
                    when Hash then symbolize_keys(value)
                    else value
                    end
        result[new_key] = new_value
        result
      }
    end
  end
end
