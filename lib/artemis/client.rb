# frozen_string_literal: true

require 'artemis/graphql_endpoint'

module Artemis
  class Client
    GRAPHQL_FILE_PATH = 'app/graphql'.freeze

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

      # TODO: Make it better faster smarter
      def path_for_graphql_file(filename)
        Rails.root.join(GRAPHQL_FILE_PATH, name.underscore, "#{filename}.graphql")
      end

      private

      def method_missing(method_name, *arguments, &block)
        new(default_context).public_send(method_name, *arguments, &block)
      rescue NoMethodError
        super
      end

      def respond_to_missing?(method_name, *_, &block)
        File.exist?(path_for_graphql_file(method_name)) || super
      end
    end

    private

    def method_missing(method_name, **arguments)
      graphql = self.class.path_for_graphql_file(method_name).read
      ast     = client.parse(graphql)

      compile_query_method!(method_name, ast)

      if arguments.empty?
        method(method_name).call
      else
        method(method_name).call(**arguments)
      end
    rescue Errno::ENOENT
      super
    end

    def respond_to_missing?(method_name, *_, &block)
      File.exist?(self.class.path_for_graphql_file(method_name)) || super
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
