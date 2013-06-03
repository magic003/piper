module Piper
  # The +Dispatcher+ module contains dispatchers that run apps with
  # different strategies. For example, {PriorityDispatcher} treats apps with
  # different priorities, the higher ones are firstly run and the lower ones
  # are run after that.
  module Dispatcher
    autoload :PriorityDispatcher,   'piper/dispatcher/priority_dispatcher'
  end
end
