require 'rspec'
require 'fileutils'
require_relative 'view'

describe DiskViewCollection do
  let(:data_path) { './data' }
  let(:collection) { DiskViewCollection.new data_path }
  before do
    FileUtils.rm_rf File.absolute_path(data_path)
  end
  it "can add and read back" do
    collection.add({ VERSION: 1, d: 1 })
    collection.add({ VERSION: 2, d: 2 })
    collection.add({ VERSION: 3, d: 3 })
    expect(collection.to_a.map{|a|a.first}.sort).to eq([1,2,3])
  end
end
