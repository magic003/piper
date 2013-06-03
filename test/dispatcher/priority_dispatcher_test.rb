require File.expand_path(File.dirname(__FILE__)) + '/../helper'

require 'date'

# A dummy task class for tests
class DummyTask 
  attr_reader :id, :value, :run_at

  def initialize(id, value)
    @id = id
    @value = value
    @run_at = nil
  end

  def run
    @value += 2
    @run_at = DateTime.now
  end

  def <=> (other)
    if @run_at.nil?
      1
    elsif other.run_at.nil?
      -1
    else
      other.run_at <=> @run_at
    end
  end

end

class NoIdTask

end

module Piper ; module Dispatcher
  class PriorityDispatcher
    attr_reader :tasks, :heap, :urgent, :thread, :running, :mutex
  end
end ; end

class TestPriorityDispatcher < Test::Unit::TestCase
  def setup
    @tasks = []
    @tasks << DummyTask.new(0,0)\
           << DummyTask.new(1,1)\
           << DummyTask.new(2,2)\
           << DummyTask.new(3,3)\
           << DummyTask.new(4,4)
  end

  def test_new
    dispatcher = Piper::Dispatcher::PriorityDispatcher.new(30*60)
    assert_equal 0, dispatcher.tasks.size

    dispatcher = Piper::Dispatcher::PriorityDispatcher.new do |dp|
      dp << @tasks
      dp.add(DummyTask.new(10,10), false)
    end

    assert_equal @tasks.size, dispatcher.urgent.size
    assert_equal 1, dispatcher.heap.size
    assert_equal 1 + @tasks.size, dispatcher.tasks.size
  end

  def test_add
    dispatcher = Piper::Dispatcher::PriorityDispatcher.new
    dispatcher.add(@tasks)
    assert_equal @tasks.size, dispatcher.urgent.size
    assert_equal @tasks.size, dispatcher.tasks.size

    dispatcher = Piper::Dispatcher::PriorityDispatcher.new
    dispatcher.add(DummyTask.new(1,1), false)
    assert_equal 0, dispatcher.urgent.size
    assert_equal 1, dispatcher.heap.size
    assert_equal 1, dispatcher.tasks.size

    dispatcher << DummyTask.new(2,2)
    assert_equal 1, dispatcher.urgent.size
    assert_equal 1, dispatcher.heap.size
    assert_equal 2, dispatcher.tasks.size

    assert_raise ArgumentError do 
      dispatcher << NoIdTask.new
    end

    assert_nothing_raised ArgumentError do
      dispatcher.add(NoIdTask.new) do |task|
        'noidtask'
      end
    end
  end

  def test_run
    dispatcher = Piper::Dispatcher::PriorityDispatcher.new(10)
    assert_nil dispatcher.thread
    assert !dispatcher.running

    dispatcher.run(Piper::FixedThreadPool.new(2))
    assert_not_nil dispatcher.thread
    sleep 0.5
    assert dispatcher.running

    dispatcher.add(@tasks)
    Thread.pass
    sleep 1
    dispatcher.mutex.synchronize do
      # some task may be running in the thread pool
      assert_equal @tasks.size, dispatcher.heap.size
      assert_equal @tasks.size, dispatcher.tasks.size
      assert_equal 0, dispatcher.urgent.size
    end

    @tasks.each_index do |i|
      assert_equal i+2, @tasks[i].value, "task should run once"
    end

    assert_equal 'sleep', dispatcher.thread.status, "thread should be sleeping"
    
    t = DummyTask.new(10,10)
    dispatcher << t
    dispatcher.mutex.synchronize do
      assert_equal 1, dispatcher.urgent.size, "should have an urgent task"
    end
    sleep 0.5
    assert_equal 12, t.value, "the urgent task should be run"
    assert_equal 'sleep', dispatcher.thread.status, "thread should be sleeping again"

    t2 = DummyTask.new(20,20)
    dispatcher.add(t2, false)
    assert_equal 'sleep', dispatcher.thread.status, "thread should still be sleeping"
    assert_equal 20, t2.value, "the task should not be run yet"

    Thread.pass
    sleep 8
    @tasks.each_index do |i|
      assert_equal i+2*2, @tasks[i].value, "task should run twice"
    end
    assert_equal 14, t.value, "the task should be run twice"
    assert_equal 22, t2.value, "the task should be run"

    assert_equal 'sleep', dispatcher.thread.status, "thread should be sleeping finally"
  end

  def test_stop
    dispatcher = Piper::Dispatcher::PriorityDispatcher.new(10)
    assert_nil dispatcher.thread
    assert !dispatcher.running
    
    dispatcher.run(Piper::FixedThreadPool.new(2))

    sleep 1
    assert_not_nil dispatcher.thread
    assert dispatcher.running

    dispatcher.stop

    assert_nil dispatcher.thread
    assert !dispatcher.running
  end

  def test_update
    dispatcher = Piper::Dispatcher::PriorityDispatcher.new(10)
  
    dispatcher.run(Piper::FixedThreadPool.new(2))
    dispatcher.add(@tasks)

    assert_nil dispatcher.update(10)
    assert_not_nil dispatcher.update(0)
  end
end

