ENV['RACK_ENV'] = 'test'
require_relative 'app'
require 'rspec'
require 'rack/test'
require 'timecop'

describe 'App' do
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  let(:entitykey) { 'user::1' }
  let(:view_schema) { { 'VERSION' => 1, 'name' => 'NEW' } }
  let(:view_version) { view_schema['VERSION'] }
  let(:view_schema2) { { 'VERSION' => 2, 'name' => 'INHERIT',
                                         'age' => 'NEW' } }
  let(:view_version2) { view_schema['VERSION'] }
  let(:time) { Time.now.to_f }

  before(:each) do
    Timecop.freeze
  end
  after(:each) do
    Timecop.return
  end

  it 'sets and gets' do
    post("/#{entitykey}",
         {view_schema: view_schema, data: { name: 'Robby' }}.to_json)
    expect(last_response).to be_ok
    expect(JSON.load(last_response.body))
      .to eq({ 'timestamp' => time, 'view_version' => view_version })
    get("/#{entitykey}/1")
    expect(last_response).to be_ok
    expect(JSON.load(last_response.body)).to eq({ 'name' => 'Robby' })
  end

  it 'sets in two versions gets in first' do
    post("/#{entitykey}",
         {view_schema: view_schema, data: { name: 'Robby' }}.to_json)
    expect(last_response).to be_ok
    expect(JSON.load(last_response.body))
      .to eq({ 'timestamp' => time, 'view_version' => view_version })
    post("/#{entitykey}",
         {view_schema: view_schema2, data: { 'age': 21 }}.to_json)
    get("/#{entitykey}/1")
    expect(last_response).to be_ok
    expect(JSON.load(last_response.body)).to eq({ 'name' => 'Robby' })
  end
end
