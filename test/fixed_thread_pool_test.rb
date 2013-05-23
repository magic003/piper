require File.expand_path(File.dirname(__FILE__)) + '/helper'

class TestFixedThreadPool < Test::Unit::TestCase

  def test_execute
    tp = Piper::FixedThreadPool.new(2)

    a = 0
    res = tp.execute do
      a += 100
    end
    assert res
    sleep 0.01
    assert_equal 100, a, "a should be updated"

    a = 1
    b = 2
    c = 3
    res = tp.execute do
      sleep 2
      a = 100
    end
    assert res

    res = tp.execute do
      sleep 2
      b = 200
    end
    assert res
    
    res = tp.execute do
      c = 300
    end
    assert !res

    sleep 3
    assert_equal 100,a,"a should be updated"
    assert_equal 200,b,"b should be updated"
    assert_equal 3,c,"c should be updated"

  end
end
