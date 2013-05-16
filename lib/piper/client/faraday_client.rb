require 'faraday'

module Piper ; module Client
  class FaradayClient < Piper::Middleware

    def initialize(app)
      super(app)
      yield Faraday if block_given?
      block = block_given? ? Proc.new : nil
      @conn = Faraday::Connection.new(&block)
    end

    def call(env)
      request = env.request
      if request
        faraday_response = @conn.run_request(request.method, request.url, 
                                        request.body, request.headers)
        res = env.response || Piper::Response.new
        res.status = faraday_response.status
        res.headers.merge!(faraday_response.headers)
        res.body = faraday_response.body

        env.response = res
      end
      @app.call(env)
    end
  end
end ; end