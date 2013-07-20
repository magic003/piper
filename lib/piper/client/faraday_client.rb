require 'faraday'

module Piper ; module Client
  class FaradayClient < Piper::Middleware
    include Log

    def initialize(app)
      super(app)
      yield Faraday if block_given?
      block = block_given? ? Proc.new : nil
      @conn = Faraday::Connection.new(&block)
    end

    def call(env)
      request = env['piper.request']
      if request.nil?
        logger.warn 'Skip because request is not set.'
      else
        faraday_response = @conn.run_request(request.method, request.url, 
                                        request.body, request.headers)
        res = env['piper.response'] || Piper::Response.new
        res.status = faraday_response.status
        res.headers.merge!(faraday_response.headers)
        res.body = faraday_response.body

        env['piper.response'] = res
      end
      @app.call(env)
    end
  end
end ; end
