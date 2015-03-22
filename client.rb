require 'uri'
require 'httparty'
require 'json'

module Solecist
  class Client

    include HTTParty

    def initialize host
      @host = host
    end

    def set key, data, view
      post_data = {
        data: data,
        view_schema: view
      }
      r = self.class.post(url_for(key), { body: post_data.to_json })
      raise "failed req: #{r.code}" if r.code == 500
      r.parsed_response
    end

    def get key
      r =self.class.get(url_for(key))
      raise "failed req: #{r.code}" if r.code == 500
      r.parsed_response
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
