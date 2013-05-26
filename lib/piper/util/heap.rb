module Piper ; module Util
  #
  # Borrow the heap implementation from {https://github.com/kanwei/algorithms \
  #   kanwei/algorithms}
  class Heap
    def initialize(ary=[], &block)
      @compare_fn = block || ->(x, y) { (x <=> y) == 1}
      @next = nil
      @size = 0
      @stored = {}

      ary.each { |e| push(e) } unless ary.empty?
    end

    def size
      @size
    end

    def push(key, value=key)
      raise ArgumentError, "Heap keys must not be nil." unless key
      node = Node.new(key, value)

      # add new node to the left of the @next node
      if @next
        node.right = @next
        node.left = @next.left
        node.left.right = node
        @next.left = node
        if @compare_fn[key, @next.key]
          @next = node
        end
      else
        @next = node
      end
      @size += 1

      @stored[key] ||= []
      @stored[key] << node
      value
    end
    alias_method :<<, :push

    def include?(key)
      @stored[key] && !@stored[key].empty?
    end

    def next
      @next && @next.value
    end

    def clear
      @next = nil
      @size = 0
      @stored = {}
      nil
    end

    def empty?
      @next.nil?
    end

    def merge!(otherheap)
      raise ArgumentError, "Trying to merge a heap with something not a heap" unless otherheap.kind_of? Piper::Util::Heap

      other_root = otherheap.instance_variable_get("@next")
      if other_root
        @stored = @stored.merge(otherheap.instance_variable_get("@stored")) { 
          |key, a, b| (a << b).flatten }
        # Insert otherheap's @next node to the left of current @next
        @next.left.right = other_root
        other_left = other_root.left
        other_root.left = @next.left
        other_left.right = @next
        @next.left = other_left

        @next = other_root if @compare_fn[other_root.key, @next.key]
      end
      @size += otherheap.size
    end

    def pop
      return nil unless @next

      popped = @next
      if @size == 1
        clear
        return popped.value
      end

      # Merge the popped's chidren into root node
      if @next.child
        @next.child.parent = nil

        # get rid of parent
        sibling = @next.child.right
        until sibling == @next.child
          sibling.parent = nil
          sibling = sibling.right
        end

        # merge the children into root. If @next is the only root node,
        # make its child the @next node
        if @next.right == @next
          @next = @next.child
        else
          next_left, next_right = @next.left, @next.right
          ch = @next.child
          @next.right.left = ch
          @next.left.right = ch.right
          ch.right.left = next_left
          ch.right = next_right
          @next = @next.right
        end
      else
        @next.left.right = @next.right
        @next.right.left = @next.left
        @next = @next.right
      end

      consolidate

      unless @stored[popped.key].delete_if { |e| e.object_id == popped.object_id }
        raise "Couldn't delete node from stored nodes hash"
      end
      @size -= 1
      
      popped.value
    end
    alias_method :next!, :pop

    def change_key(key, new_key, delete=false)
      return nil if !include?(key) || (key == new_key)
      
      # Max heap can only increase key, while min heap can only decrease
      raise "Changing this key would not maintain heap property!" unless (delete || @compare_fn[new_key, key])

      delete_first_in_stored = Proc.new do |k|
        @stored[k].each_with_index do |e,i|
          break @stored[k].delete_at(i) if e.key == k
        end
      end
      node = delete_first_in_stored[key]
      node.key = new_key
      @stored[new_key] ||= []
      @stored[new_key] << node
      parent = node.parent
      if parent
        if delete || @compare_fn[new_key, parent.key]
          cut(node, parent)
          cascading_cut(parent)
        end
      end
      
      if delete || @compare_fn[node.key, @next.key]
        @next = node
      end
      [node.key, node.value]
    end

    def delete(key)
      pop if change_key(key, nil, true)
    end

    private

    def link_nodes(child, parent)
      # link the child's siblings
      child.left.right = child.right
      child.right.left = child.left

      child.parent = parent

      # if parent doesn't have children, make new child its only child
      if parent.child.nil?
        parent.child = child.right = child.left = child
      else # otherwise insert new child into parent's children list
        current_child = parent.child
        child.left = current_child
        child.right = current_child.right
        current_child.right.left = child
        current_child.right = child
      end

      parent.degree += 1
      child.marked = false
    end

    def consolidate
      roots = []
      root = @next
      max = root
      # get the root nodes
      loop do
        roots << root
        root = root.right
        break if root == @next
      end

      degrees = []
      roots.each do |r|
        max = r if @compare_fn[r.key, max.key]

        if degrees[r.degree].nil? # no other node with the same degree
          degrees[r.degree] = r
        else
          degree = r.degree
          until degrees[degree].nil? do
            other_root_with_degree = degrees[degree]
            if @compare_fn[r.key, other_root_with_degree.key]
              larger, smaller = r, other_root_with_degree
            else
              larger, smaller = other_root_with_degree, r
            end

            link_nodes(smaller, larger)
            degrees[degree] = nil
            r = larger
            degree += 1
          end
          degrees[degree] = r
          # this fixes a bug with duplicate keys not being in the right order
          max = r if max.key == r.key
        end
      end
      @next = max
    end

    def cascading_cut(node)
      p = node.parent
      if p
        if node.marked?
          cut(node, p)
          cascading_cut(p)
        else
          node.marked = true
        end
      end
    end

    # remove x from y's children and add x to the root node list
    def cut(x, y)
      x.left.right = x.right
      x.right.left = x.left
      y.degree -= 1
      if y.degree == 0
        y.child = nil
      elsif y.child == x
        y.child = x.right
      end
      x.right = @next
      x.left = @next.left
      @next.left = x
      x.left.right = x
      x.parent = nil
      x.marked = false
    end

    Node = Struct.new(:key, :value, :parent, :child, :left, :right, :degree,
                      :marked) do
      def initialize(key, value)
        super(key, value, nil, nil, self, self, 0, false)
      end

      alias_method :marked?, :marked
    end
  end
end ; end
