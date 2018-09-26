# frozen_string_literal: true

require 'net/http/persistent'

module Artemis
  module Adapters
    class NetHttpPersistentAdapter < AbstractAdapter
      attr_reader :_connection

      def initialize(uri, service_name: , timeout: , pool_size: )
        super

        @_connection = Net::HTTP::Persistent.new(name: name, proxy: proxy, pool_size: pool_size)
      end

      # Public: Extension point for subclasses to customize the Net:HTTP client
      #
      # Returns a Net::HTTP object
      def connection
        _connection
      end
    end
  end
end
