require File.expand_path(File.dirname(__FILE__)) + '/helper'

require 'stringio'

class Foo
  include Piper::Log

  def run
    logger.error "test logger"
  end
end

class Bar
  include Piper::Log

  def run
    logger.error "test logger"
  end
end

module FooM
  include Piper::Log

  def test
    logger.error "test logger"
  end
end

class Baz
  include FooM

  def run
    logger.error "test logger"
  end
end

class LogTest < Test::Unit::TestCase
  def setup
    @str = StringIO.new
    Piper::Log.logdev = @str
  end

  def test_log_in_class
    Foo.new.run
    assert @str.string.include? 'Foo#run'

    Bar.new.run
    assert @str.string.include? 'Bar#run'
  end

  def test_log_included_twice
    baz = Baz.new
    baz.test
    assert @str.string.include? 'Baz#test'

    @str.string = ''
    baz.run
    assert @str.string.include? 'Baz#run'
  end
end
