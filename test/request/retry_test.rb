require File.expand_path(File.dirname(__FILE__)) + '/../helper'

class DummyApp
  attr_reader :value

  def initialize
    @value = 0
  end

  def call(env)
    @value += 1
    if @value == 1
      fail ArgumentError
    else
      fail Errno::ETIMEDOUT
    end
  end
end

class DummyApp2
  attr_reader :value

  def initialize
    @value = 0
  end

  def call(env)
    @value += 1
    fail unless @value > 1
  end
end

class RetryTest < Test::Unit::TestCase
  def test_new
    r = Piper::Request::Retry.new(nil)
    options = r.instance_variable_get('@options')
    assert_equal 3, options.max
    assert_equal 0, options.interval
    assert_equal [Errno::ETIMEDOUT, 'Timeout::Error'], options.exceptions
    assert_not_nil r.instance_variable_get('@errmatch')

    r = Piper::Request::Retry.new(nil,
                              {max:5, interval:2, exceptions:[RuntimeError]})
    options = r.instance_variable_get('@options')
    assert_equal 5, options.max
    assert_equal 2, options.interval
    assert_equal [RuntimeError], options.exceptions
    assert_not_nil r.instance_variable_get('@errmatch')
  end 

  def test_call
    app = DummyApp.new
    r = Piper::Request::Retry.new(app, {exceptions:[ArgumentError, 
                                  Errno::ETIMEDOUT]})
    assert_raise Errno::ETIMEDOUT do
      r.call(nil)
    end
    assert_equal 3, app.value

    app = DummyApp2.new
    r = Piper::Request::Retry.new(app, {exceptions:[RuntimeError]})
    assert_nothing_raised do
      r.call(nil)
    end
    assert_equal 2, app.value
  end
end
