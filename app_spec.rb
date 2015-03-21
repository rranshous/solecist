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
  let(:view_schema3) {
    { 'VERSION' => 3,
      'name' => 'INHERIT', 'age' => 'INHERIT',
      'proper_name' => {
        'UP' => {
           'source' => ['name'],
           'transformer' => 'lambda{|name|"Sir #{name}"}'
         }
       }
    }
  }

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

  context 'sets in two views' do
    before(:each) do # each is wrong
      post("/#{entitykey}",
           {view_schema: view_schema, data: { name: 'Robby' }}.to_json)
      post("/#{entitykey}",
           {view_schema: view_schema2, data: { 'age': 21 }}.to_json)
    end
    it 'gets in first view' do
      get("/#{entitykey}/1")
      expect(last_response).to be_ok
      expect(JSON.load(last_response.body)).to eq({ 'name' => 'Robby' })
    end
    it 'gets in second view' do
      get("/#{entitykey}/2")
      expect(last_response).to be_ok
      expect(JSON.load(last_response.body)).to eq({ 'name' => 'Robby',
                                                    'age' => 21 })
    end
  end

  context 'uses view w/ transformation' do
    it 'can get using view w/ transformation' do
      post("/#{entitykey}",
           {view_schema: view_schema, data: { name: 'Robby' }}.to_json)
      post("/#{entitykey}",
           {view_schema: view_schema2, data: { 'age': 21 }}.to_json)
      post("/#{entitykey}",
           {view_schema: view_schema3, data: { }}.to_json)
      get("/#{entitykey}/3")
      expect(last_response).to be_ok
      expect(JSON.load(last_response.body)).to eq({ 'name' => 'Robby',
                                                    'age' => 21,
                                                    'proper_name' => 'Sir Robby' })
    end
  end
end
