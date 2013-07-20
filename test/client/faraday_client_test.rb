require File.expand_path(File.dirname(__FILE__)) + '/../helper'

require 'faraday'

class FaradayClientTest < Test::Unit::TestCase
  def setup
    stubs = Faraday::Adapter::Test::Stubs.new do |ss|
      ss.get('/foo.json?q=piper') do |stub|
        [200, {'Content-Type' => 'application/json'}, '{"foo" : "piper"}'] 
      end
      ss.get('/foo.xml?q=piper') do |stub|
        [200, {'Content-Type' => 'text/xml'}, '<foo>piper</foo>'] 
      end
      ss.post('/bar', 'name=piper&age=1') do |stub|
        body = '{"name": "piper", "age": 1}'
        [200, {'Content-Length' => body.size}, body] 
      end
      ss.post('/bar') do |stub|
        [400, {}, nil]
      end
    end
    @client = Piper::Client::FaradayClient.new(Proc.new {}) do |conn|
      conn.adapter :test, stubs
    end
  end

  def test_call
    env = {}

    @client.call(env)
    assert_nil env['piper.response']

    ######

    req = Piper::Request.new(:get, '/foo.json') do |r|
      r.queries['q'] = 'piper'
    end
    env = { 'piper.request' => req }

    @client.call(env)
    res = env['piper.response']
    assert_equal 200, res.status
    assert_equal 'application/json', res.headers['Content-Type']
    assert_equal '{"foo" : "piper"}', res.body

    ######
    
    req = Piper::Request.new(:get, '/foo.xml') do |r|
      r.queries['q'] = 'piper'
    end
    env = { 'piper.request' => req }

    @client.call(env)
    res = env['piper.response']
    assert_equal 200, res.status
    assert_equal 'text/xml', res.headers['Content-Type']
    assert_equal '<foo>piper</foo>', res.body

    ######

    req = Piper::Request.new(:post, '/bar') do |r|
      r.body = 'name=piper&age=1'
    end
    env = { 'piper.request' => req }

    @client.call(env)
    res = env['piper.response']
    assert_equal 200, res.status
    body = '{"name": "piper", "age": 1}'
    assert_equal body.size, res.headers['Content-Length']
    assert_equal body, res.body

    ######
    
    req = Piper::Request.new(:post, '/bar')
    env = { 'piper.request' => req }

    @client.call(env)
    res = env['piper.response']
    assert_equal 400, res.status
  end
end
