module Piper
  Response = Struct.new(:status, :headers, :body) do 
    def initialize(status=nil, headers={}, body=nil)
      super(status, headers, body)
      yield self if block_given?
    end
  end
end
