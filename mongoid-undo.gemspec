require './lib/mongoid/undo/version'

Gem::Specification.new do |gem|
  gem.name          = 'mongoid-undo'
  gem.version       = Mongoid::Undo::VERSION
  gem.authors       = 'Mario Uher'
  gem.email         = 'uher.mario@gmail.com'
  gem.homepage      = 'https://github.com/haihappen/mongoid-undo'
  gem.summary       = 'Super simple undo for your Mongoid app.'
  gem.description   = 'mongoid-undo provides a super simple and easy to use undo system for Mongo apps.'

  gem.files         = `git ls-files`.split("\n")
  gem.require_path  = 'lib'

  gem.add_dependency 'mongoid'
end
