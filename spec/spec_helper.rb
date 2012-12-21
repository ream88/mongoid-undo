require 'minitest/autorun'
require 'minitest/pride'
require 'minitest/spec'

require 'active_support/testing/assertions'

require './lib/mongoid/undo'

Mongoid.load!(File.expand_path('../mongoid.yml', __FILE__), 'test')
