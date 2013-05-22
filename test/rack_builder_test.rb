require File.expand_path(File.dirname(__FILE__)) + '/helper'

# Open RackBuilder to access middlewares
module Piper
  class RackBuilder
    attr_accessor :middlewares
  end
end

class FooMiddleware < Piper::Middleware
  def initialize(app)
    super(app)
  end

  def call(env)
    @app.call(env)
  end
end

class BarMiddleware < Piper::Middleware
  def initialize(app)
    super(app)
  end

  def call(env)
    @app.call(env)
  end
end

class RackBuilderTest < Test::Unit::TestCase
  
  def test_lock
    builder = Piper::RackBuilder.new

    assert !builder.locked?

    builder.lock!
    assert builder.locked?
  end

  def test_use
    builder = nil
    assert_nothing_raised RuntimeError do
      builder = create_builder
    end

    assert_equal 2, builder.middlewares.size

    builder.lock!

    assert_raise RuntimeError do
      builder.use FooMiddleware
    end
  end

  def test_app
    builder = create_builder
    app = builder.app

    assert builder.locked?
    assert_equal FooMiddleware, app.class

    assert_equal app, builder.app
  end

  private

  def create_builder
    Piper::RackBuilder.new do |builder|
      builder.use FooMiddleware
      builder.use BarMiddleware
    end
  end
end
