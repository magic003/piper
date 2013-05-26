require File.expand_path(File.dirname(__FILE__)) + '/../helper'

class HeapTest < Test::Unit::TestCase

  def test_size
    heap = Piper::Util::Heap.new
    assert_equal 0, heap.size

    heap = Piper::Util::Heap.new([1,2,3])
    assert_equal 3, heap.size
  end

  def test_push
    heap = Piper::Util::Heap.new
    heap.push(1)
    assert_equal 1, heap.size

    heap << 2
    assert_equal 2, heap.size
  end

  def test_include?
    heap = Piper::Util::Heap.new
    assert !heap.include?(1)

    heap.push(1)
    assert heap.include?(1)
  end

  def test_next
    heap = Piper::Util::Heap.new
    assert_nil heap.next

    heap.push(1)
    assert_equal 1, heap.next
  end

  def test_clear
    heap = random_heap
    assert_not_nil heap.next
    assert_equal @num_items, heap.size

    heap.clear
    assert_nil heap.next
    assert_equal 0, heap.size
    assert_equal 0, heap.instance_variable_get("@stored").size
  end

  def test_empty?
    heap = Piper::Util::Heap.new
    assert heap.empty?

    heap.push(1)
    assert !heap.empty?
  end

  def test_merge!
    # Should raise exception if merged with a non-heap
    heap = Piper::Util::Heap.new
    assert_raise ArgumentError do
      heap.merge!(nil)
    end

    assert_raise ArgumentError do
      heap.merge!([])
    end

    # should merge with another heap
    heap = random_heap
    numbers = [1,2,3,4,5,6,7,8]
    otherheap = Piper::Util::Heap.new(numbers)
    heap.merge!(otherheap)

    assert_equal numbers.size + @num_items, heap.size

    ordered = []
    ordered << heap.pop until heap.empty?

    assert_equal ordered, (@random_array + numbers).sort.reverse
  end

  def test_pop
    heap = Piper::Util::Heap.new
    assert_nil heap.pop

    heap.push(1)
    assert_equal 1, heap.pop
    assert_equal 0, heap.size

    heap = random_heap
    ordered = []
    ordered << heap.pop until heap.empty?
    
    assert_equal ordered, @random_array.sort.reverse
  end

  def test_change_key
    numbers = [1,2,3,4,5,6,7,8,9,10,100,101]
    heap = Piper::Util::Heap.new(numbers) { |x,y| (x <=> y) == -1 }
    heap.change_key(101, 50)
    
    heap.pop
    heap.pop
    heap.change_key(8, 0)
    
    ordered = []
    ordered << heap.next! until heap.empty?
    assert_equal [8,3,4,5,6,7,9,10,101,100], ordered
  end

  def test_delete
    heap = random_heap
    assert_nil heap.delete(:nonexisting)
    assert_equal @num_items, heap.size

    numbers = [1,2,3,4,5,6,7,8,9,10,100,101]
    heap = Piper::Util::Heap.new(numbers) { |x,y| (x <=> y) == -1 }
    heap.delete(5)
    heap.pop
    heap.pop
    heap.delete(100)
    ordered = []
    ordered << heap.next! until heap.empty?
    assert_equal [3,4,6,7,8,9,10,101], ordered

    heap = random_heap
    assert_equal @random_array[0], heap.delete(@random_array[0])
    assert_equal @random_array[1], heap.delete(@random_array[1])

    ordered = []
    ordered << heap.next! until heap.empty?
    assert_equal @random_array[2..-1].sort.reverse, ordered

    heap = random_heap
    ordered = []
    @random_array.size.times do |t|
      ordered << heap.delete(@random_array[t])
    end
    assert heap.empty?
    assert_equal @random_array, ordered
  end

  private

  def random_heap
    @random_array = []
    @num_items = 100
    @num_items.times { |x| @random_array << rand(@num_items) }
    Piper::Util::Heap.new(@random_array)
  end
end
