module Piper
  class Middleware
    def initialize(app = nil)
      @app = app
    end
  end
end
