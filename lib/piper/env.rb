module Piper
  Env = Struct.new(:request, :response, :credentials, :extra) do
    def initialize(request=nil, response=nil, credentials={}, extra={}) 
      super(request, response, credentials, extra)
      yield self if block_given?
    end
  end
end
