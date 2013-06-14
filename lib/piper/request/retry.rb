module Piper
  #
  # Borrow from {https://github.com/lostisland/faraday/blob/master/lib/faraday/request/retry.rb Retry}
  #
  class Request::Retry < Piper::Middleware
    Options = Struct.new(:max, :interval, :exceptions) do
      def initialize(max=3, interval=0, exceptions=nil)
        super(max,interval,[Errno::ETIMEDOUT, 'Timeout::Error'])
      end

      def self.from(hsh)
        options = Options.new
        options.max = hsh[:max].to_i unless hsh[:max].nil?
        options.interval = hsh[:interval].to_i unless hsh[:interval].nil?
        options.exceptions = hsh[:exceptions] unless hsh[:exceptions].nil?
        options
      end
    end

    def initialize(app, options=nil)
      super(app)
      @options = Options.from(options || {})
      @errmatch = build_exception_matcher(@options.exceptions)
    end

    def call(env)
      retries = @options.max
      begin
        @app.call(env)
      rescue @errmatch
        if retries > 1
          retries -= 1
          sleep @options.interval if @options.interval > 0
          retry
        end
        raise
      end
    end

    private

    def build_exception_matcher(exceptions)
      matcher = Module.new
      
      (class << matcher; self; end).class_eval do
        define_method(:===) do |error|
          exceptions.any? do |ex|
            if ex.is_a? Module then error.is_a? ex
            else error.class.to_s == ex.to_s
            end
          end
        end
      end
      matcher
    end
  end
end
