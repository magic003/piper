require 'thread'

module Piper ; module Dispatcher
  # The +PriorityDispatcher+ determines which the next task is based on the
  # priority of the task. A bootstrap task has a high priority, so it is 
  # executed first. Other tasks will be executed after all high-priority tasks 
  # are done.
  #
  # If there are high-priority tasks, it dispatches them immediately. For 
  # low-priority ones, it tries to rerun the same task in a fixed interval,
  # which is specified in the constructor. The interval is calculate roughly.
  #
  # @example Creates a priority dispatcher, add tasks to it and dispatch
  #
  #   tasks = []
  #   # load tasks...
  #
  #   dispatcher = PriorityDispatcher.new
  #   dispatcher.add_tasks(tasks)
  #   dispatcher.dispatch(ThreadPool::FixedThreadPool.new(10))
  #   sleep(100)
  #   dispatcher.stop
  class PriorityDispatcher
    include Log

    # Creates a priority dispatcher.
    #
    # @param [Integer] interval interval in seconds to rerun the same task
    def initialize(interval=600, comparator=nil)
      @interval_seconds = interval
      @heap = Piper::Util::Heap.new do |x,y|
        comparator.nil? ? (x <=> y) == 1 : comparator[x,y] == 1
      end
      @tasks = {}
      @urgent = []
      @running = false
      @thread = nil
      @mutex = Mutex.new

      yield self if block_given?
    end

    # Adds tasks for dispatching.
    #
    # @param [Tasks::Task,Array<Tasks::Task>] tasks added tasks
    def add(tasks, run_at_once=true)
      tasks = [tasks] unless tasks.respond_to?(:each)
      @mutex.synchronize do
        tasks.each do |t|
          if run_at_once
            @urgent << t
          else
            @heap << t
          end
          id = if t.respond_to?(:id)
                 t.id
               elsif block_given? 
                 yield t
               end
          if id
            @tasks[id] = t
          else
            fail ArgumentError, 'Either a task#id method or a block that \
              returns the task id should be provided'
          end
        end
      end
      wake_thread if run_at_once
    end
    alias_method :<<, :add
    
    # Dispatches tasks. 
    #
    # A background thread is created to dispatch tasks one by one, so this 
    # method returns at once. The thread runs forever, to stop it, call {#stop}.
    #
    # @param [ThreadPool] thread_pool thread pool to run the tasks
    def run(thread_pool)
      if @thread.nil?
        @mutex.synchronize do
          @thread = create_dispatch_thread(thread_pool) if @thread.nil?
        end
      end
    end

    # Stops dispatching.
    #
    # @note The task dispatching is stopped at once, but for the already
    #   dispatched tasks, they will keep running until finished.
    def stop
      @running = false
      @thread = nil
    end

    # Update a task.
    #
    # @param [Integer] id task id
    # @param [Hash] hs hash contains task properties to be updated
    # @return [Tasks::Task] the updated task, nil if not found
    #
    # @see Tasks::Task#update
    # @see Tasks::DeliciousTask#update
    # @see Tasks::FacebookTask#update
    # @see Tasks::ReaditlaterTask#update
    # @see Tasks::TwitterTask#update
    def update(id)
      t = @tasks[id]
      yield t if t && block_given?
      t
    end

    private

    def create_dispatch_thread(thread_pool)
      Thread.new do 
        @running = true
        while @running
          task = next_task
          unless task.nil?
            while @running do
              # wrap the task in the proc so it won't get changed
              wrapper = Proc.new do |t|
                Proc.new do 
                  t.run
                  done(t)
                end
              end

              run = thread_pool.execute(wrapper[task])
              break if run
              logger.warn 'No idle thread. Retry in 3 seconds.'
              #sleep 3 # try it later
              Thread.pass
            end
          end
          sleep interval unless urgent? # run next task after an interval
        end
      end
    end

    def urgent?
      not @urgent.empty?
    end

    def next_task
      @mutex.synchronize do
        @urgent.shift || @heap.pop
      end
    end

    def done(task)
      @mutex.synchronize do
        @heap << task
      end
    end

    # Returns the interval time to run a task in seconds.
    # 
    # The dispatcher tries to rerun the same task in a fixed interval, so this
    # method calculates the interval based on the task quantity.
    #
    # @return [Integer] interval in seconds
    def interval
      return 0 if urgent?
      # rough value is OK, so don't call @mutex.synchronize
      task_num = @heap.size
      task_num == 0 ? @interval_seconds : @interval_seconds / task_num
      #urgent? ? 0 : @interval_seconds
    end

    # Wakes up the dispatching thread.
    def wake_thread
      unless @thread.nil? || !'sleep'.eql?(@thread.status)
        @thread.run
      end
    end
  end
end ; end
