# frozen_string_literal: true

require 'active_support/core_ext/object/blank'
require 'graphql/client/http'

module Artemis
  module Adapters
    class AbstractAdapter < ::GraphQL::Client::HTTP
      attr_reader :service_name, :timeout, :pool_size

      EMPTY_HEADERS = {}.freeze

      DEFAULT_HEADERS = {
        "Accept" => "application/json",
        "Content-Type" => "application/json"
      }.freeze

      def initialize(uri, service_name: , timeout: , pool_size: , adapter_options: {})
        raise ArgumentError, "url is required (given `#{uri.inspect}')" if uri.blank?

        super(uri) # Do not pass in the block to avoid getting #headers and #connection overridden.

        @service_name = service_name.to_s
        @timeout      = timeout
        @pool_size    = pool_size
      end

      # Public: Extension point for subclasses to set custom request headers.
      #
      # Returns Hash of String header names and values.
      def headers(_context)
        _context[:headers] || EMPTY_HEADERS
      end

      # Public: Make an HTTP request for GraphQL query.
      #
      # A subclass that inherits from +AbstractAdapter+ can override this method if it needs more flexibility for how
      # it makes a request.
      #
      # For more details, see +GraphQL::Client::HTTP#execute+.
      def execute(*)
        super
      end

      # Public: Extension point for subclasses to customize the Net:HTTP client
      #
      # A subclass that inherits from +AbstractAdapter+ should returns a Net::HTTP object or an object that responds
      # to +request+ that is given a Net::HTTP request object.
      def connection
        raise "AbstractAdapter is an abstract class that can not be instantiated!"
      end
    end
  end
end
