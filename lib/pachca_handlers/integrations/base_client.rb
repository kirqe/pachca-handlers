# frozen_string_literal: true

require 'faraday'
require 'faraday/retry'
require 'uri'

module PachcaHandlers
  module Integrations
    class BaseClient
      attr_reader :base_url, :headers

      def initialize(base_url, headers = {})
        @base_url = base_url
        @headers = headers
        @conn = build_connection
      end

      def get(path, params = {})
        @conn.get(path, params)
      end

      def post(path, body = {})
        @conn.post(path, body)
      end

      def put(path, body = {})
        @conn.put(path, body)
      end

      def delete(path, params = {})
        @conn.delete(path, params)
      end

      def patch(path, body = {})
        @conn.patch(path, body)
      end

      class << self
        def get(url, params = {})
          new(URI(url)).get('', params)
        end
      end

      private

      def build_connection
        Faraday.new(url: @base_url) do |faraday|
          faraday.request :json
          faraday.response :json
          faraday.request :retry, max: 3, interval: 0.05, backoff_factor: 2

          @headers.each do |key, value|
            faraday.headers[key] = value
          end

          faraday.adapter Faraday.default_adapter
        end
      end
    end
  end
end
