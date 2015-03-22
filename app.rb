require 'sinatra'
require 'json'
require_relative 'helpers'
require_relative 'solecist'

store = Solecist::MemoryStore.new
$solecist = Solecist.new store

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
  puts "view schema: #{payload['view_schema']}"
  view_schema = transformations_to_lambda symbolize_keys payload['view_schema']
  info = $solecist.write(entitykey, view_schema, data, metadata, timestamp)
  content_type 'application/json'
  {'timestamp' => info[:time], 'view_version' => info[:view_version]}.to_json
end
