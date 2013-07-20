require File.expand_path(File.dirname(__FILE__)) + '/../helper'

class TwitterAuthenticationTest < Test::Unit::TestCase

  BASE_URL = 'https://api.twitter.com/1.1/statuses/user_timeline.json'

  def setup
    @app = Piper::Request::TwitterAuthentication.new(Proc.new {})
  end

  def test_call
    env = {}

    @app.call(env)
    assert_nil env['piper.response']

    ######
    req = Piper::Request.new(:get, BASE_URL)

    env = { 'piper.request' => req }
    
    assert_raise RuntimeError do
      @app.call(env)
    end

    env['piper.credentials'] = {} if env['piper.credentials'].nil?
    env['piper.credentials'][Piper::Request::TwitterAuthentication::CONSUMER_KEY] = 'xxx'

    assert_raise RuntimeError do
      @app.call(env)
    end

    env['piper.credentials'][Piper::Request::TwitterAuthentication::CONSUMER_SECRET] =
      'xxxx'

    assert_raise RuntimeError do
      @app.call(env)
    end

    ######

    env['piper.credentials'][Piper::Request::TwitterAuthentication::TOKEN] = 'xxx'
    env['piper.credentials'][Piper::Request::TwitterAuthentication::TOKEN_SECRET] = 'xxx'

    @app.call(env)
    assert_not_nil env['piper.request'].headers['Authorization']

    ######
    
    env['piper.request'].headers = {}
    env['piper.request'].queries['count'] = 200

    @app.call(env)
    assert_not_nil env['piper.request'].headers['Authorization']
  end
end
