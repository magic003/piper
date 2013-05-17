require File.expand_path(File.dirname(__FILE__)) + '/../helper'

class TwitterAuthenticationTest < Test::Unit::TestCase

  BASE_URL = 'https://api.twitter.com/1.1/statuses/user_timeline.json'

  def setup
    @app = Piper::TwitterAuthentication.new(Proc.new {})
  end

  def test_call
    env = Piper::Env.new

    @app.call(env)
    assert_nil env.response

    ######
    req = Piper::Request.new(:get, BASE_URL)

    env = Piper::Env.new do |e|
      e.request = req
    end
    
    assert_raise RuntimeError do
      @app.call(env)
    end

    env.credentials[Piper::TwitterAuthentication::CONSUMER_KEY] = 'xxx'

    assert_raise RuntimeError do
      @app.call(env)
    end

    env.credentials[Piper::TwitterAuthentication::CONSUMER_SECRET] =
      'xxxx'

    assert_raise RuntimeError do
      @app.call(env)
    end

    ######

    env.credentials[Piper::TwitterAuthentication::TOKEN] = 'xxx'
    env.credentials[Piper::TwitterAuthentication::TOKEN_SECRET] = 'xxx'

    @app.call(env)
    assert_not_nil env.request.headers['Authorization']

    ######
    
    env.request.headers = {}
    env.request.queries['count'] = 200

    @app.call(env)
    assert_not_nil env.request.headers['Authorization']
  end
end
