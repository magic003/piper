require File.expand_path(File.dirname(__FILE__)) + '/../helper'

require 'faraday'

class TestBareFaradayClient < Test::Unit::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new do |stub|
      stub.get('/foo') { [200, {}, 'egg'] }
    end
    @client = Piper::Client::BareFaradayClient.new(Proc.new {}) do |faraday|
      faraday.builder.adapter :test, @stubs
    end
  end

  def test_new
    f1 = nil
    f2 = nil
    Piper::Client::BareFaradayClient.new(nil) do |faraday|
      f1 = faraday
    end
    Piper::Client::BareFaradayClient.new(nil) do |faraday|
      f2 = faraday
    end
    assert_not_nil f1
    assert_not_nil f2
    assert_equal f1, f2, 'Should be the same Faraday object'
    assert_equal f1.default_connection, f2.default_connection, 'Should use the same connection'
  end

  def test_call

  end
end
