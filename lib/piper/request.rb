require 'uri'

module Piper
  Request = Struct.new(:method, :path, :params, :headers, :body) do
    def initialize(method, path, params={}, headers={}, body=nil)
      super(method, path, params, headers, body)
      yield self if block_given?
    end

    def url
      params.size > 0 ? "#{path}?#{URI.encode_www_form(params)}" : path.dup
    end
  end
end
