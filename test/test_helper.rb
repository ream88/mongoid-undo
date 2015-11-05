$: << File.expand_path('../../lib', __FILE__)
require 'minitest/autorun'
require 'minitest/pride'

require 'mongoid/undo'

Mongoid.load!(File.expand_path('../mongoid.yml', __FILE__), 'test')

if defined?(Mongo)
  Mongo::Logger.logger.level = Logger::WARN
end

class Minitest::Test
  alias_method :assert_not, :refute
  alias_method :assert_not_equal, :refute_equal

  # Copied from activesupport/lib/active_support/testing/assertions.rb
  def assert_difference(expression, difference = 1, message = nil, &block)
    expressions = Array(expression)

    exps = expressions.map { |e|
      e.respond_to?(:call) ? e : lambda { eval(e, block.binding) }
    }
    before = exps.map { |e| e.call }

    yield

    expressions.zip(exps).each_with_index do |(code, e), i|
      error  = "#{code.inspect} didn't change by #{difference}"
      error  = "#{message}.\n#{error}" if message
      assert_equal(before[i] + difference, e.call, error)
    end
  end

  def assert_no_difference(expression, message = nil, &block)
    assert_difference expression, 0, message, &block
  end
end
