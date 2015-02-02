require 'sinatra'
require 'json'
require_relative 'solecist'

store = Solecist::MemoryStore.new
$solecist = Solecist.new store

get '/:entitykey/:view_version' do |entitykey, view_version|
  timestamp = params['timestamp'].nil? ? nil : params['timestamp'].to_f
  metadata = JSON.load(params[:metadata] || '{}')
  data = $solecist.read(entitykey,
                        view_version.to_i,
                        symbolize_keys(metadata),
                        timestamp)
  data.to_json
end

post '/:entitykey' do |entitykey|
  request.body.rewind
  payload = JSON.parse request.body.read
  timestamp = payload['timestamp'].nil? ? nil : payload['timestamp'].to_f
  metadata = payload['metadata'] ||= {}
  data = symbolize_keys payload['data']
  view_schema = symbolize_keys payload['view_schema']
  info = $solecist.write(entitykey, view_schema, data, metadata, timestamp)
  content_type 'application/json'
  {'timestamp' => info[:time], 'view_version' => info[:view_version]}.to_json
end

helpers do
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
