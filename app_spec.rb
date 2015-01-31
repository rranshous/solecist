require 'rspec'
require_relative 'app'

describe 'app' do

  let(:store) { MemoryStore.new }
  let(:solecist) { Solecist.new(store) }

  it 'can write using diff views and read newesting using diff views' do
    data_view_v1 = {
      VERSION: 1,
      name: :NEW,
      phone: :NEW
    }
    data_view_v2 = { 
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
          transformer: lambda{|name|name.split(' ')[1..-1]}
        },
        DOWN: {
          source: [:fname, :lname],
          transformer: lambda{|fname,lname|"#{fname} #{lname}"},
          target: :name
        }
      },
      phone: :INHERIT
    }
    data_view_v3 = {
      VERSION: 3,
      fname: :INHERIT, lname: :INHERIT, phone: :INHERIT,
      contact: :NEW
    }
    solecist.write(
      'user::1',
      data_view_v1,
      { name: 'Robby Ranchous', phone: '1231233' }
    )
    solecist.write(
      'user::1',
      data_view_v2,
      { lname: 'Ranshous' }
    )
    solecist.write(
      'user::1',
      data_view_v3,
      { contact: 'Lizz' }
    )
    expect( solecist.read(
      'user::1',
      data_view_v1
    )).to eq({ name: 'Robby Ranshous',
               phone: '1231233' })
    expect( solecist.read(
      'user::1',
      data_view_v2
    )).to eq({ fname: 'Robby', lname: 'Ranshous',
               phone: '1231233' })
    expect( solecist.read(
      'user::1',
      data_view_v3
    )).to eq({ fname: 'Robby', lname: 'Ranshous',
               phone: '1231233', contact: 'Lizz' })
  end
end
