# frozen_string_literal: true

require 'active_support/core_ext/hash/deep_merge'
require 'active_support/core_ext/module/attribute_accessors'
require 'active_support/core_ext/string/inflections'

require 'artemis/graphql_endpoint'
require 'artemis/exceptions'

module Artemis
  class Client
    cattr_accessor :query_paths

    attr_reader :client

    def initialize(context = {})
      @client = self.class.endpoint.instantiate_client(context)
    end

    class << self
      attr_writer :default_context

      def default_context
        @default_context ||= { }
      end

      def endpoint
        Artemis::GraphQLEndpoint.lookup(name)
      end

      def with_context(context)
        new(default_context.deep_merge(context))
      end

      def resolve_graphql_file_path(filename)
        graphql_file_paths.detect {|path| path.end_with?("#{name.underscore}/#{filename}.graphql") }
      end

      def graphql_file_paths
        @graphql_file_paths ||= query_paths.flat_map {|path| Dir["#{path}/#{name.underscore}/*.graphql"] }
      end

      def preload!
        graphql_file_paths.each do |path|
          load_constant(File.basename(path, File.extname(path)).camelize)
        end
      end

      def load_constant(const_name)
        graphql_file = resolve_graphql_file_path(const_name.to_s.underscore)

        if graphql_file
          graphql = File.open(graphql_file).read
          ast     = endpoint.instantiate_client.parse(graphql)

          const_set(const_name, ast)
        end
      end
      alias load_query load_constant

      private

      def const_missing(const_name)
        load_constant(const_name) || super
      end

      def method_missing(method_name, *arguments, &block)
        if resolve_graphql_file_path(method_name)
          new(default_context).public_send(method_name, *arguments, &block)
        else
          super
        end
      end

      def respond_to_missing?(method_name, *_, &block)
        resolve_graphql_file_path(method_name) || super
      end
    end

    private

    def method_missing(method_name, **arguments)
      if self.class.resolve_graphql_file_path(method_name)
        client.query(
          self.class.const_get(method_name.to_s.camelize),
          variables: arguments ? arguments.deep_transform_keys {|key| key.to_s.camelize(:lower) } : {},
          context: (arguments && arguments[:context]) || {}
        )
      else
        super
      end
    end

    def respond_to_missing?(method_name, *_, &block)
      self.class.resolve_graphql_file_path(method_name) || super
    end

    def compile_query_method!(method_name)
      const_name = method_name.to_s.camelize

      self.class.send(:class_eval, <<-RUBY, __FILE__, __LINE__ + 1)
        def #{method_name}(context: {}, **arguments)
          client.query(
            self.class::#{const_name},
            variables: arguments.deep_transform_keys {|key| key.to_s.camelize(:lower) },
            context: context
          )
        end
      RUBY
    end
  end
end
