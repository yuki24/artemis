# frozen_string_literal: true

require 'json'
require 'net/http'

require 'artemis/adapters/abstract_adapter'
require 'artemis/exceptions'

module Artemis
  module Adapters
    class NetHttpAdapter < AbstractAdapter
      # Makes an HTTP request for GraphQL query.
      def execute(document:, operation_name: nil, variables: {}, callbacks: nil, context: {})
        request = Net::HTTP::Post.new(uri.request_uri)

        request.basic_auth(uri.user, uri.password) if uri.user || uri.password

        request["Accept"] = "application/json"
        request["Content-Type"] = "application/json"
        headers(context).each { |name, value| request[name] = value }

        body = {}
        body["query"] = document.to_query_string
        body["variables"] = variables if variables.any?
        body["operationName"] = operation_name if operation_name
        request.body = JSON.generate(body)

        request_callbacks&.before_request_callbacks&.each do |callback|
          callback.call(request, request.to_hash, request.body, context)
        end

        response = connection.request(request)

        request_callbacks&.after_request_callbacks&.each do |callback|
          callback.call(response, response.code.to_i, response.body, context)
        end

        case response.code.to_i
        when 200, 400
          JSON.parse(response.body)
        when 500..599
          raise Artemis::GraphQLServerError, "Received server error status #{response.code}: #{response.body}"
        else
          { "errors" => [{ "message" => "#{response.code} #{response.message}" }] }
        end
      end

      # Returns a fresh Net::HTTP object that creates a new connection.
      def connection
        Net::HTTP.new(uri.host, uri.port).tap do |client|
          client.use_ssl       = uri.scheme == "https"
          client.open_timeout  = timeout
          client.read_timeout  = timeout
          client.write_timeout = timeout if client.respond_to?(:write_timeout=)
        end
      end
    end
  end
end
