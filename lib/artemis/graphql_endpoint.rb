# frozen_string_literal: true

require 'active_support/core_ext/hash/deep_merge'
require 'active_support/core_ext/hash/keys'
require 'active_support/core_ext/module/attribute_accessors'
require 'active_support/core_ext/object/blank'
require 'active_support/core_ext/string/inflections'
require 'graphql/client'

require 'artemis/adapters'
require 'artemis/exceptions'

module Artemis
  class GraphQLEndpoint

    # Whether or not to suppress warnings on schema load. Use it with caution.
    #
    # @private
    cattr_accessor :suppress_warnings_on_schema_load
    self.suppress_warnings_on_schema_load = false

    # Hash object that holds references to adapter instances.
    ENDPOINT_INSTANCES = {}

    private_constant :ENDPOINT_INSTANCES

    class << self
      ##
      # Provides an endpoint instance specified in the +configuration+. If the endpoint is not found in
      # +ENDPOINT_INSTANCES+, it'll raise an exception.
      def lookup(service_name)
        ENDPOINT_INSTANCES[service_name.to_s.underscore] || raise(Artemis::EndpointNotFound, "Service `#{service_name}' not registered.")
      end

      def register!(service_name, configurations)
        ENDPOINT_INSTANCES[service_name.to_s.underscore] = new(service_name.to_s, configurations.symbolize_keys)
      end

      ##
      # Returns the registered services as an array.
      #
      def registered_services
        ENDPOINT_INSTANCES.keys
      end
    end

    attr_reader :name, :url, :adapter, :timeout, :schema_path, :pool_size

    def initialize(name, url: nil, adapter: :net_http, timeout: 10, schema_path: nil, pool_size: 25)
      @name, @url, @adapter, @timeout, @schema_path, @pool_size = name.to_s, url, adapter, timeout, schema_path, pool_size

      @mutex_for_schema     = Mutex.new
      @mutex_for_connection = Mutex.new
    end

    def schema
      org, $stderr = $stderr, File.new("/dev/null", "w") if self.class.suppress_warnings_on_schema_load

      @schema || @mutex_for_schema.synchronize do
        @schema ||= ::GraphQL::Client.load_schema(schema_path.presence || connection)
      end
    ensure
      $stderr = org if self.class.suppress_warnings_on_schema_load
    end
    alias load_schema! schema

    def connection
      @connection || @mutex_for_connection.synchronize do
        @connection ||= ::Artemis::Adapters.lookup(adapter).new(url, service_name: name, timeout: timeout, pool_size: pool_size)
      end
    end
  end
end
