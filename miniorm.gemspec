 Gem::Specification.new do |s|
   s.name          = 'miniORM'
   s.version       = '0.0.0'
   s.date          = '2018-11-28'
   s.summary       = 'A lightweight ORM'
   s.description   = 'An ActiveRecord-esque ORM adaptor'
   s.authors       = ['Lassiter Gregg']
   s.email         = 'public@lassitergregg.com'
   s.files         = Dir['lib/**/*.rb']
   s.require_paths = ["lib"]
   s.homepage      =
     'http://rubygems.org/gems/miniORM'
   s.license       = 'MIT'
   s.add_runtime_dependency 'sqlite3', '~> 1.3'
 end