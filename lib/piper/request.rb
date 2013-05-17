require 'uri'

module Piper
  Request = Struct.new(:method, :path, :queries, :headers, :body) do
    def initialize(method, path, queries={}, headers={}, body=nil)
      super(method, path, queries, headers, body)
      yield self if block_given?
    end

    def url
      queries.size > 0 ? "#{path}?#{URI.encode_www_form(queries)}" : path.dup
    end

  end

end
