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
      @redis.zadd key, time, to_write.to_json
    end
    def read key, view_version
      raw_datas = @redis.zrange key, 0, -1
      datas = raw_datas.map { |d| JSON.load d }
      datas
    end
    def keys
      @redis.keys
    end
  end
end
