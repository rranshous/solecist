require 'json'
require 'fileutils'

class Solecist
  class DiskStore

    def initialize data_dir
      @data_dir = File.join(File.absolute_path(data_dir),'key_data')
      FileUtils.mkdir_p @data_dir
    end

    def write key, data, view_version, metadata, time
      to_write = { data: data, view_version: view_version,
                   metadata: metadata, timestamp: time, key: key }
      path = File.join(@data_dir,key,"#{time}.json")
      FileUtils.mkdir_p File.dirname(path)
      File.open(path, 'w') do |fh|
        fh.write(to_write.to_json)
      end
    end

    def read key
      [].tap do |datas|
        Dir[File.join(@data_dir,key,'*.json')]
        .sort_by{ |p| File.basename(p).split('.',2).first }
        .each do |path|
          datas << symbolize_keys(JSON.load(File.read(path)))
        end
      end
    end

    def keys
      Dir[File.join(@data_dir,'*')].map{ |p| File.basename(p) }
    end

    private
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
