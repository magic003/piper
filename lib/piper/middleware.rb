module Piper
  class Middleware
    def initialize(app = nil)
      @app = app
    end
  end
  
  # Autoload the middlewares
  Request.autoload :TwitterAuthentication, 'piper/request/twitter_authentication'
end
