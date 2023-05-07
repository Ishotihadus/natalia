# frozen_string_literal: true

require 'net/http'

module Natalia
  module Utils
    def self.curl_get(url, params = {})
      uri = URI(url)
      uri.query = URI.encode_www_form(URI.decode_www_form(uri.query || '') + URI.decode_www_form(URI.encode_www_form(params)))

      request = Net::HTTP::Get.new(uri)
      request['user-agent'] = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Safari/537.36 Edg/114.0.0.0'
      yield(request) if block_given?

      Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == 'https') {|http| http.request(request)}
    end

    def self.curl_post(url)
      uri = URI(url)

      request = Net::HTTP::Post.new(uri)
      request['user-agent'] = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Safari/537.36 Edg/114.0.0.0'
      yield(request) if block_given?

      Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == 'https') {|http| http.request(request)}
    end
  end
end
