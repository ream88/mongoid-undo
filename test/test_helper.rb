$LOAD_PATH << File.expand_path('../../lib', __FILE__)
require 'minitest/autorun'
require 'minitest/pride'

require 'mongoid/undo'

Mongoid.load!(File.expand_path('../mongoid.yml', __FILE__), 'test')

Mongo::Logger.logger.level = Logger::WARN if defined?(Mongo)

class Minitest::Test
  # Copied from activesupport/lib/active_support/testing/assertions.rb
  def assert_difference(expression, difference = 1, message = nil, &block)
    expressions = Array(expression)

    exps = expressions.map do |e|
      e.respond_to?(:call) ? e : -> { eval(e, block.binding) }
    end
    before = exps.map(&:call)

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
