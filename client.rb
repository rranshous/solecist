require 'uri'
require 'httparty'
require 'json'

class Solecist
  class Client

    include HTTParty

    def initialize host
      @host = host
    end

    def set key, data, view, metadata={}
      post_data = {
        data: data,
        view_schema: view,
        metadata: metadata
      }
      r = self.class.post(url_for(key), { body: post_data.to_json })
      raise "failed req: #{r.code}" if r.code == 500
      r.parsed_response
    end

    def get key, metadata=nil
      query = metadata.nil? ? nil : { metadata: metadata.to_json }
      r = self.class.get(url_for(key), query: query)
      raise "failed req: #{r.code}" if r.code == 500
      return nil if r.code == 404
      r.parsed_response
    end

    def all
      r = self.class.get(URI.join(host, '/'))
      raise "failed req: #{r.code}" if r.code == 500
      r.parsed_response.map do |url|
        self.class.get(url).parsed_response
      end
    end

    def keys
      r = self.class.get(URI.join(host, '/'))
      raise "failed req: #{r.code}" if r.code == 500
      r.parsed_response.map{|l|l.split('/').last}
    end

    private
    def url_for key
      URI.join(host,"/#{key}")
    end
    def host
      @host || ENV['SOLECIST_URL']
    end
  end
end
