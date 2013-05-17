module Piper
  class Middleware
    def initialize(app = nil)
      @app = app
    end
  end
  
  autoload :TwitterAuthentication, 'piper/request/twitter_authentication'
end
