require_relative 'disk_store'
require 'fileutils'
require 'rspec'

describe Solecist do

  let(:data_path) { 'data' }
  let(:client) { Solecist::DiskStore.new(data_path) }

  before do
    FileUtils.rm_rf File.absolute_path(data_path)
  end

  it 'can read back what it wrote in the correct order' do
    client.write('key1', { data1: 1 }, 1, { meta: 1 }, 1234)
    client.write('key1', { data2: 2 }, 2, { meta: 2 }, 2234)
    client.write('key1', { data3: 3 }, 3, { meta: 3 }, 3334)
    expect(client.read('key1')).to eq([
      { data: { data1: 1 }, view_version: 1, metadata: { meta: 1 },
        timestamp: 1234, key: 'key1' },
      { data: { data2: 2 }, view_version: 2, metadata: { meta: 2 },
        timestamp: 2234, key: 'key1' },
      { data: { data3: 3 }, view_version: 3, metadata: { meta: 3 },
        timestamp: 3334, key: 'key1' }
    ])
  end

  it 'can get back the keys' do
    client.write('key1', nil, nil, nil, nil)
    client.write('key2', nil, nil, nil, nil)
    client.write('key3', nil, nil, nil, nil)
    expect(client.keys.sort).to eq(['key1','key2','key3'])
  end

end
