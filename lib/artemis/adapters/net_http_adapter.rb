# frozen_string_literal: true

require 'net/http'
require 'artemis/adapters/abstract_adapter'

module Artemis
  module Adapters
    class NetHttpAdapter < AbstractAdapter
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
