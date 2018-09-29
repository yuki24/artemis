# frozen_string_literal: true

require 'active_support/core_ext/module/attribute_accessors'

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

      def lookup_graphql_file(filename)
        path = graphql_file_paths.detect do |path|
          path.end_with?("#{name.underscore}/#{filename}.graphql")
        end

        if path.nil?
          raise GraphQLFileNotFound, "could not found #{filename}.graphql in:\n" \
                                     "    #{query_paths.map {|path| File.join(path, name.underscore) }.join("\n    ")}\n\n"
        end

        path
      end

      def graphql_file_paths
        @graphql_file_paths ||= query_paths.flat_map do |path|
          Dir["#{path}/#{name.underscore}/*.graphql"]
        end
      end

      private

      def method_missing(method_name, *arguments, &block)
        new(default_context).public_send(method_name, *arguments, &block)
      rescue NoMethodError
        super
      end

      def respond_to_missing?(method_name, *_, &block)
        File.exist?(lookup_graphql_file(method_name).to_s) || super
      end
    end

    private

    def method_missing(method_name, **arguments)
      graphql = File.open(self.class.lookup_graphql_file(method_name)).read
      ast     = client.parse(graphql)

      compile_query_method!(method_name, ast)

      if arguments.empty?
        method(method_name).call
      else
        method(method_name).call(**arguments)
      end
    rescue Artemis::GraphQLFileNotFound
      super
    end

    def respond_to_missing?(method_name, *_, &block)
      File.exist?(self.class.lookup_graphql_file(method_name).to_s) || super
    end

    def compile_query_method!(method_name, ast)
      const_name = method_name.to_s.camelize

      # A hack that suppresses `warning: already initialized constant Constant...'
      begin
        self.class.const_get(const_name)
        self.class.send(:remove_const, const_name)
      rescue NameError
        # no-op...
      end

      self.class.const_set(const_name, ast)

      if ast.definition_node.variables.empty?
        eval <<-RUBY, nil, __FILE__, __LINE__ + 1
          def #{method_name}(context: {})
            client.query(self.class::#{const_name}, context: context)
          end
        RUBY
      else
        eval <<-RUBY, nil, __FILE__, __LINE__ + 1
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
end
