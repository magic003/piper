require 'faraday'

module Piper ; module Client
  class BareFaradayClient < Piper::Middleware

    def initialize(app)
      super(app)
      yield Faraday if block_given?
    end

    def call(env)
      request = env.request
      if request
        faraday_response = Faraday.run_request(request.method, request.url, 
                                        request.body, request.headers)
        response = Piper::Response.new(faraday_response.status,
                                       faraday_response.headers,
                                       faraday_response.body)
        env.response = response
      end
      @app.call(env)
    end
  end
end ; end
