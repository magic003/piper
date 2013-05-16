module Piper
  Env = Struct.new(:request, :response, :credentials) do
    def initialize(request=nil, response=nil, credentials={}) 
      super(request, response, credentials)
      yield self if block_given?
    end
  end
end
