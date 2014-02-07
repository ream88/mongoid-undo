$: << File.expand_path('../../lib', __FILE__)
require 'minitest/autorun'
require 'minitest/pride'

require 'mongoid/undo'

Mongoid.load!(File.expand_path('../mongoid.yml', __FILE__), 'test')

class Minitest::Test
  alias_method :assert_not, :refute
end
