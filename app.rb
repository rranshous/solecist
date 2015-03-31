require 'sinatra'
require 'json'
require_relative 'helpers'
require_relative 'solecist'

view_collection = nil
configure(:development,:test) do
  puts "using memory store"
  $store = Solecist::MemoryStore.new
  view_collection = ViewCollection.new
end
configure(:production) do
  puts "using redis store"
  $store = Solecist::RedisStore.new
  view_collection = RedisViewCollection.new
end

$solecist = Solecist.new $store, view_collection

get '/' do
  content_type 'application/json'
  $store.keys.map do |k|
    URI.join("http://#{request.host}:#{request.port}","/#{k}")
  end.to_json
end

get '/:entitykey' do |entitykey|
  timestamp = params['timestamp'].nil? ? nil : params['timestamp'].to_f
  metadata = JSON.load(params[:metadata] || '{}')
  data = $solecist.read(entitykey,
                        nil,
                        symbolize_keys(metadata),
                        timestamp)
  content_type 'application/json'
  data.to_json
end

get '/:entitykey/:view_version' do |entitykey, view_version|
  timestamp = params['timestamp'].nil? ? nil : params['timestamp'].to_f
  metadata = JSON.load(params[:metadata] || '{}')
  data = $solecist.read(entitykey,
                        view_version.to_i,
                        symbolize_keys(metadata),
                        timestamp)
  content_type 'application/json'
  data.to_json
end

post '/:entitykey' do |entitykey|
  request.body.rewind
  payload = JSON.parse request.body.read
  timestamp = payload['timestamp'].nil? ? nil : payload['timestamp'].to_f
  metadata = payload['metadata'] ||= {}
  data = symbolize_keys payload['data']
  view_schema = transformations_to_lambda symbolize_keys payload['view_schema']
  info = $solecist.write(entitykey, view_schema, data, metadata, timestamp)
  content_type 'application/json'
  {'timestamp' => info[:time], 'view_version' => info[:view_version]}.to_json
end
