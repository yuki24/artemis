# frozen_string_literal: true

require 'delegate'

require 'active_support/configurable'
require 'active_support/core_ext/hash/deep_merge'
require 'active_support/core_ext/string/inflections'

require 'artemis/graphql_endpoint'
require 'artemis/exceptions'

module Artemis
  class Client
    include ActiveSupport::Configurable

    # The paths in which the Artemis client looks for files that have the +.graphql+ extension.
    # In a rails app, this value will be set to +["app/operations"]+ by Artemis' +Artemis::Railtie+.
    config.query_paths = []

    # Default context that is appended to every GraphQL request for the client.
    config.default_context = {}

    # List of before callbacks that get invoked in every +execute+ call.
    #
    # @api  private
    config.before_callbacks = []

    # List of after callbacks that get invoked in every +execute+ call.
    #
    # @api private
    config.after_callbacks = []

    # Returns a plain +GraphQL::Client+ object. For more details please refer to the official documentation for
    # {the +graphql-client+ gem}[https://github.com/github/graphql-client].
    attr_reader :client

    # Creates a new instance of the GraphQL client for the service.
    #
    #   # app/operations/github/user.graphql
    #   query($id: String!) {
    #     user(login: $id) {
    #       name
    #     }
    #   }
    #
    #   # app/operations/github.rb
    #   class GitHub < Artemis::Client
    #   end
    #
    #   github = GitHub.new
    #   github.user(id: 'yuki24').data.user.name # => "Yuki Nishijima"
    #
    #   github = GitHub.new(context: { headers: { Authorization: "bearer ..." } })
    #   github.user(id: 'yuki24').data.user.name # => "Yuki Nishijima"
    #
    def initialize(context = {})
      @client = self.class.instantiate_client(context)
    end

    class << self
      delegate :query_paths, :default_context, :query_paths=, :default_context=, to: :config

      alias with_context new

      def endpoint
        Artemis::GraphQLEndpoint.lookup(name)
      end

      def instantiate_client(context = {})
        ::GraphQL::Client.new(schema: endpoint.schema, execute: connection(context))
      end

      # Defines a callback that will get called right before the
      # client's execute method is executed.
      #
      #   class GitHub < Artemis::Client
      #
      #     before_execute do |document, operation_name, variables, context|
      #       Analytics.log(operation_name, variables, context[:user_id])
      #     end
      #
      #     ...
      #   end
      #
      def before_execute(&block)
        config.before_callbacks << block
      end

      # Defines a callback that will get called right after the
      # client's execute method has finished.
      #
      #   class GitHub < Artemis::Client
      #
      #     after_execute do |data, errors, extensions|
      #       if errors.present?
      #         Rails.logger.error(errors.to_json)
      #       end
      #     end
      #
      #     ...
      #   end
      #
      def after_execute(&block)
        config.after_callbacks << block
      end

      def resolve_graphql_file_path(filename, fragment: false)
        namespace = name.underscore
        filename  = filename.to_s.underscore

        graphql_file_paths.detect do |path|
          path.end_with?("#{namespace}/#{filename}.graphql") ||
            (fragment && filename.end_with?('fragment') && path.end_with?("#{namespace}/_#{filename}.graphql"))
        end
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
        graphql_file = resolve_graphql_file_path(const_name.to_s.underscore, fragment: true)

        if graphql_file
          graphql = File.open(graphql_file).read
          ast     = instantiate_client.parse(graphql)

          const_set(const_name, ast)
        end
      end
      alias load_query load_constant

      # @api private
      def connection(context = {})
        Executor.new(endpoint.connection, callbacks, default_context.deep_merge(context))
      end

      private

      # @api private
      def const_missing(const_name)
        load_constant(const_name) || super
      end

      # @api private
      def method_missing(method_name, *arguments, &block)
        if resolve_graphql_file_path(method_name)
          new(default_context).public_send(method_name, *arguments, &block)
        else
          super
        end
      end

      # @api private
      def respond_to_missing?(method_name, *_, &block)
        resolve_graphql_file_path(method_name) || super
      end

      Callbacks = Struct.new(:before_callbacks, :after_callbacks)

      private_constant :Callbacks

      # @api private
      def callbacks
        Callbacks.new(config.before_callbacks, config.after_callbacks)
      end
    end

    private

    # @api private
    def method_missing(method_name, context: {}, **arguments)
      if self.class.resolve_graphql_file_path(method_name)
        const_name = method_name.to_s.camelize

        # This check will be unnecessary once we drop support for Ruby 2.4 and earlier
        if !self.class.const_get(const_name).is_a?(GraphQL::Client::OperationDefinition)
          self.class.load_constant(const_name)
        end

        client.query(
          self.class.const_get(const_name),
          variables: arguments.deep_transform_keys {|key| key.to_s.camelize(:lower) },
          context: context
        )
      else
        super
      end
    end

    # @api private
    def respond_to_missing?(method_name, *_, &block)
      self.class.resolve_graphql_file_path(method_name) || super
    end

    # @api private
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

  # @api private
  class Executor < SimpleDelegator
    def initialize(connection, callbacks, default_context)
      super(connection)

      @callbacks = callbacks
      @default_context = default_context
    end

    def execute(document:, operation_name: nil, variables: {}, context: {})
      _context = @default_context.deep_merge(context)

      @callbacks.before_callbacks.each do |callback|
        callback.call(document, operation_name, variables, _context)
      end

      response = __getobj__.execute(document: document, operation_name: operation_name, variables: variables, context: _context)

      @callbacks.after_callbacks.each do |callback|
        callback.call(response['data'], response['errors'], response['extensions'])
      end

      response
    end
  end

  private_constant :Executor
end
