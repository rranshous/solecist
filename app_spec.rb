require 'rspec'
require 'timecop'
require_relative 'app'

describe 'app' do

  let(:store) { MemoryStore.new }
  let(:solecist) { Solecist.new(store) }
  let(:entity_key) { 'user::1' }
  let(:data_view_v1) do
    {
      VERSION: 1,
      name: :NEW,
      phone: :NEW
    }
  end
  let(:data_view_v2) do
    { 
      VERSION: 2,
      fname: {
        UP: {
          source: [:name],
          transformer: lambda{|name|name.split(' ').first}
        },
        DOWN: {
          source: [:fname, :lname],
          transformer: lambda{|fname,lname|"#{fname} #{lname}"},
          target: :name
        }
      },
      lname: {
        UP: {
          source: [:name],
          transformer: lambda{|name|name.split(' ')[1..-1].join(' ')}
        },
        DOWN: {
          source: [:fname, :lname],
          transformer: lambda{|fname,lname|"#{fname} #{lname}"},
          target: :name
        }
      },
      phone: :INHERIT
    }
  end
  let(:data_view_v3) do
    {
      VERSION: 3,
      fname: :INHERIT, lname: :INHERIT, phone: :INHERIT,
      contact: :NEW
    }
  end

  it 'can read and write using same version' do
    solecist.write(entity_key, data_view_v1,
      { name: 'Robby Ranchous', phone: '1231233' })
    expect(solecist.read(entity_key, data_view_v1))
      .to eq({ name: 'Robby Ranchous', phone: '1231233' })
  end

  context 'three view versions, three writes' do
    before(:each) do
      solecist.write(entity_key, data_view_v1,
        { name: 'Robby Ranchous', phone: '1231233' })
      solecist.write(entity_key, data_view_v2, { lname: 'Ranshous' })
      solecist.write(entity_key, data_view_v3, { contact: 'Lizz' })
    end
    it 'can read back using first version' do
      expect(solecist.read(entity_key, data_view_v1))
        .to eq({ name: 'Robby Ranshous', phone: '1231233' })
    end
    it 'can read back using second version (transformations)' do
      expect(solecist.read(entity_key, data_view_v2))
        .to eq({ fname: 'Robby', lname: 'Ranshous', phone: '1231233' })
    end
    it 'can read back using third version' do
      expect(solecist.read(entity_key, data_view_v3))
        .to eq({ fname: 'Robby', lname: 'Ranshous',
                 phone: '1231233', contact: 'Lizz' })
    end
  end

  context 'three view versions, three in order, three out of order writes' do
    before(:each) do
      solecist.write(entity_key, data_view_v1,
        { name: 'Robby Ranchous', phone: '1231233' })
      solecist.write(entity_key, data_view_v2, { lname: 'Ranshous' })
      solecist.write(entity_key, data_view_v3, { contact: 'Lizz' })
      solecist.write(entity_key, data_view_v2, { fname: 'Bobby' })
      solecist.write(entity_key, data_view_v1, { name: 'Bobby Knight' })
      solecist.write(entity_key, data_view_v3, { contact: 'Lizz M' })
    end
    it 'can read back using first version' do
      expect(solecist.read(entity_key, data_view_v1))
        .to eq({ name: 'Bobby Knight', phone: '1231233' })
    end
    it 'can read back using second version (transformations)' do
      expect(solecist.read(entity_key, data_view_v2))
        .to eq({ fname: 'Bobby', lname: 'Knight', phone: '1231233' })
    end
    it 'can read back using third version' do
      expect(solecist.read(entity_key, data_view_v3))
        .to eq({ fname: 'Bobby', lname: 'Knight',
                 phone: '1231233', contact: 'Lizz M' })
    end
  end

  context 'write versions in reverse order' do
    before(:each) do
      solecist.write(entity_key, data_view_v3, { contact: 'Lizz' })
      solecist.write(entity_key, data_view_v2, { lname: 'Ranshous' })
      solecist.write(entity_key, data_view_v1,
        { name: 'Robby Ranchous', phone: '1231233' })
      solecist.write(entity_key, data_view_v2, { fname: 'Bobby' })
      solecist.write(entity_key, data_view_v1, { name: 'Bobby Knight' })
      solecist.write(entity_key, data_view_v3, { contact: 'Lizz M' })
    end
    it 'can read back using first version' do
      expect(solecist.read(entity_key, data_view_v1))
        .to eq({ name: 'Bobby Knight', phone: '1231233' })
    end
    it 'can read back using second version (transformations)' do
      expect(solecist.read(entity_key, data_view_v2))
        .to eq({ fname: 'Bobby', lname: 'Knight', phone: '1231233' })
    end
    it 'can read back using third version' do
      expect(solecist.read(entity_key, data_view_v3))
        .to eq({ fname: 'Bobby', lname: 'Knight',
                 phone: '1231233', contact: 'Lizz M' })
    end
  end

  context 'write out of order with timestamps' do
    let(:earlier){Time.now.to_f}
    let(:later){earlier + 100}
    before(:each) do
      Timecop.freeze(earlier+200)
      solecist.write(entity_key, data_view_v3, { fname: 'Robby' }, earlier)
      solecist.write(entity_key, data_view_v3, { fname: 'Phil' }, later)
    end
    after(:each) do
      Timecop.return
    end
    it 'reads back w/ "earlier" value' do
      expect(solecist.read(entity_key, data_view_v3)).to eq({fname: 'Phil'})
    end
    it 'can read back from arbitrary point in time' do
      expect(solecist.read(entity_key, data_view_v3, earlier+50))
        .to eq({fname: 'Robby'})
    end
  end

end
