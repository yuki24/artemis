# frozen_string_literal: true

require 'delegate'

require 'net/http/persistent'

require 'artemis/adapters/net_http_adapter'

module Artemis
  module Adapters
    class NetHttpPersistentAdapter < NetHttpAdapter
      attr_reader :_connection, :raw_connection

      def initialize(uri, service_name: , timeout: , pool_size: )
        super

        @raw_connection = Net::HTTP::Persistent.new(name: service_name, pool_size: pool_size)
        @raw_connection.open_timeout = timeout
        @raw_connection.read_timeout = timeout

        @_connection = ConnectionWrapper.new(@raw_connection, uri)
      end

      # Public: Extension point for subclasses to customize the Net:HTTP client
      #
      # Returns a Net::HTTP object
      def connection
        _connection
      end

      class ConnectionWrapper < SimpleDelegator
        def initialize(obj, url)
          super(obj)

          @url = url
        end

        def request(req)
          __getobj__.request(@url, req)
        end
      end

      private_constant :ConnectionWrapper
    end
  end
end
