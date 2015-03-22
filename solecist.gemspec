Gem::Specification.new do |s|
  s.name          = 'solecist'
  s.version       = '0.0.1'
  s.licenses      = ['BeerWare']
  s.summary       = "client for solecist document store"
  s.description   = "client for solecist document store"
  s.authors       = ["Robby Ranshous"]
  s.email         = "rranshous@gmail.com"
  s.files         = ["client.rb"]
  s.homepage      = "https://github.com/rranshous/streamworker"
  s.require_paths = ['.']
  s.add_dependency 'redis'
  s.add_dependency 'redis-objects'
  s.add_dependency 'httparty'
end

