# frozen_string_literal: true

require 'json'
require 'net/http'

require 'artemis/adapters/abstract_adapter'
require 'artemis/exceptions'

module Artemis
  module Adapters
    class NetHttpAdapter < AbstractAdapter
      def multiplex(queries, context: {})
        make_request({ _json: queries }, context)
      end

      # Makes an HTTP request for GraphQL query.
      def execute(document:, operation_name: nil, variables: {}, context: {})
        body = {}
        body["query"] = document.to_query_string
        body["variables"] = variables if variables.any?
        body["operationName"] = operation_name if operation_name

        make_request(body, context)
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

      private

      def make_request(body, context)
        request = Net::HTTP::Post.new(uri.request_uri)
        request.basic_auth(uri.user, uri.password) if uri.user || uri.password
        request.body = JSON.generate(body)

        DEFAULT_HEADERS.merge(headers(context)).each { |name, value| request[name] = value }

        response = connection.request(request)

        case response.code.to_i
        when 200, 400
          JSON.parse(response.body)
        when 500..599
          raise Artemis::GraphQLServerError, "Received server error status #{response.code}: #{response.body}"
        else
          { "errors" => [{ "message" => "#{response.code} #{response.message}" }] }
        end
      end
    end
  end
end
