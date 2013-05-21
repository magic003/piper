require 'uri'
require 'openssl'
require 'base64'

module Piper 
  class Request::TwitterAuthentication < Piper::Middleware
    include Log

    CONSUMER_KEY = 'consumer_key'
    CONSUMER_SECRET= 'consumer_secret'
    TOKEN = 'token'
    TOKEN_SECRET = 'token_secret'

    def initialize(app, consumer_key=nil, consumer_secret=nil)
      super(app)
      @consumer_key = consumer_key
      @consumer_secret = consumer_secret
    end

    def call(env)
      request = env.request
      error = validate_credentials(env)
      if request.nil?
        logger.warn 'Skip because request is not set.'
      elsif error.nil?
        creds = env.credentials
        consumer_key = creds[CONSUMER_KEY] || @consumer_key
        consumer_secret = creds[CONSUMER_SECRET] || @consumer_secret
        unless request.headers['Authorization'].nil?
          logger.warn 'Replace the existing Authorization header: ' +
            request.headers['Authorization']
        end
        request.headers['Authorization'] = oauth_header(consumer_key,
                                                        consumer_secret,
                                                        creds[TOKEN],
                                                        creds[TOKEN_SECRET],
                                                        request.method,
                                                        request.path,
                                                        request.queries)
      else
        logger.error error
        fail error
      end
      @app.call(env)
    end

    private

    def validate_credentials(env)
      creds = env.credentials
      error = nil
      if creds.nil?
        error = 'Credentials are not set in env'
      elsif @consumer_key.nil? && creds[CONSUMER_KEY].nil?
        error = 'Consumer key is not provided in credentials'
      elsif @consumer_secret.nil? && creds[CONSUMER_SECRET].nil?
        error = 'Consumer secret is not provided in credentials'
      elsif creds[TOKEN].nil?
        error = 'Token is not provided in the credentials'
      elsif creds[TOKEN_SECRET].nil?
        error = 'Token secret is not provided in credentials'
      end

      error
    end

    # Encodes a string using URL form encoding.
    #
    # @param [String] string a string to be encoded
    # @return [String] encoded string
    def percent_encode(string)
      return URI.encode_www_form_component(string).gsub('*', '%2A')
    end
    
    # Generates the OAuth value for +Authorization+ header.
    #
    # @param [String] consumer_key consumer key of the twitter  application
    # @param [String] consumer_secret consumer_secret of the twitter application
    # @param [String] token access token for a user
    # @param [String] token_secret token secret for a user
    # @param [String,Symbol] method request method type
    # @param [String] url request url
    # @param [Hash] queries url queries
    # @return [String] +Authentication+ header value
    def oauth_header(consumer_key, consumer_secret, token, token_secret, 
                     method, url, queries)
      oauth_pairs = {
        'oauth_consumer_key' => consumer_key,
        'oauth_nonce' => Array.new(5) { rand(256) }.pack('C*').unpack('H*').first,
        'oauth_signature_method' => 'HMAC-SHA1',
        'oauth_timestamp' => Time.now.to_i.to_s,
        'oauth_token' => token,
        'oauth_version' => '1.0'
      }
      oauth_pairs['oauth_signature'] = percent_encode(
                                        oauth_signature(consumer_secret,
                                          token_secret, method, url, 
                                          oauth_pairs, queries))
      pairs = []
      oauth_pairs.each do |key,val|
          pairs.push( "#{key.to_s}=\"#{val.to_s}\"")
      end
      'OAuth ' + pairs.join(', ')
    end
    
    # Generates the oauth signature.
    #
    # @param [String] consumer_secret consumer_secret of the twitter application
    # @param [String] token_secret token secret for a user
    # @param [String,Symbol] method request method type
    # @param [String] url request url
    # @param [Hash] oauth_pairs the 7 key/value oauth pairs, accept the
    #   signature
    # @param [Hash] queries url queries used for the request
    # @return [String] signature
    def oauth_signature(consumer_secret, token_secret, method,
                        url, oauth_pairs, queries)
      queries.merge!(oauth_pairs)
      pairs = []
      queries.sort.each do |key, val|
        pairs.push("#{percent_encode(key.to_s)}=#{percent_encode(val.to_s)}")
      end
      query_string = pairs.join('&')

      base_str = [method.to_s.upcase, percent_encode(url), 
                    percent_encode(query_string)].join('&')

      key = percent_encode(consumer_secret) + '&' + 
              percent_encode(token_secret)

      digest = OpenSSL::Digest::Digest.new('sha1')
      hmac = OpenSSL::HMAC.digest(digest, key, base_str)

      Base64.encode64(hmac).chomp.gsub(/\n/, '')
    end

  end
end
