# frozen_string_literal: true

require 'artemis/adapters/abstract_adapter'

module Artemis
  module Adapters
    class MultiDomainAdapter < AbstractAdapter
      attr_reader :adapter

      def initialize(_uri, service_name: , timeout: , pool_size: , adapter_options: {})
        if adapter_options[:adapter] == :multi_domain
          raise ArgumentError, "You can not use the :multi_domain adapter with the :multi_domain adapter."
        end

        @connection_by_url    = {}
        @service_name         = service_name.to_s
        @timeout              = timeout
        @pool_size            = pool_size
        @adapter              = adapter_options[:adapter] || :net_http
        @mutex_for_connection = Mutex.new
      end

      # Makes an HTTP request for GraphQL query.
      def execute(document:, operation_name: nil, variables: {}, context: {})
        url = context[:url]

        if url.nil?
          raise ArgumentError, 'The MultiDomain adapter requires a url on every request. Please specify a url with a context: ' \
                               'Client.with_context(url: "https://awesomeshop.domain.conm")'
        end

        connection_for_url(url).execute(document: document, operation_name: operation_name, variables: variables, context: context)
      end

      def connection
        raise NotImplementedError, "Calling the #connection method without a URI is not supported. Please use the " \
                                   "#connection_for_url(uri) instead."
      end

      def connection_for_url(url)
        @connection_by_url[url.to_s] || @mutex_for_connection.synchronize do
          @connection_by_url[url.to_s] ||= ::Artemis::Adapters.lookup(adapter).new(url, service_name: service_name, timeout: timeout, pool_size: pool_size)
        end
      end
    end
  end
end
