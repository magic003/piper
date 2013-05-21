module Piper

  class RackBuilder

    INNER_APP = Proc.new

    def initialize
      @middlewares = []
      yield self if block_given?
    end

    def lock!
      @middlewares.freeze
    end

    def locked?
      @middlewares.frozen?
    end

    def use(klass, *args, &block)
      raise_if_locked
      @middlewares << Proc.new { |app| klass.new(app, args, &block) }
    end

    def app
      @app ||= begin
                 lock!
                 to_app(INNER_APP)
               end
    end

    private

    def to_app(inner_app)
      @middlewares.reverse.reduce(inner_app) { |a, e| e.call(a)}
    end

    def raise_if_locked
      if locked?
        raise RuntimeError, "Cannot modify middleware stack after it is running"
      end
    end
  end
end
