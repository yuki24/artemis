# frozen_string_literal: true

require 'delegate'

require 'active_support/callbacks'
require 'active_support/core_ext/enumerable'
require 'active_support/core_ext/hash/deep_merge'
require 'active_support/core_ext/module/attribute_accessors'
require 'active_support/core_ext/module/delegation'
require 'active_support/core_ext/string/inflections'

require 'artemis/graphql_endpoint'
require 'artemis/exceptions'

module Artemis

  # = Artemis Client Callbacks
  #
  # Artemis client provides hooks during the life cycle of a graphQL request. Callbacks allow you
  # to trigger logic during this cycle. Available callbacks are:
  #
  # * <tt>before_execute</tt>
  # * <tt>around_execute</tt>
  # * <tt>after_execute</tt>
  #
  # NOTE: Calling the same callback multiple times will overwrite previous callback definitions.
  #
  module Callbacks
    extend ActiveSupport::Concern

    included do
      class << self
        attr_accessor :callback_runner
      end
    end

    class AbstractCallbackRunner
      include ActiveSupport::Callbacks

      define_callbacks :execute

      attr_reader :document, :operation_name, :variables, :context
      attr_accessor :response

      def initialize(document, operation_name, variables, context)
        @document, @operation_name, @variables, @context = document, operation_name, variables, context
      end

      class << self
        def before_execute(*filters, &block)
          set_callback(:execute, :before, *filters) do |runner|
            block.call(runner.document, runner.operation_name, runner.variables, runner.context)
          end
        end

        def after_execute(*filters, &block)
          set_callback(:execute, :after, *filters) do |runner|
            response = runner.response

            block.call(response[:data] || response['data'], response[:errors] || response['errors'])
          end
        end
      end
    end

    private_constant :AbstractCallbackRunner

    # These methods will be included into any Artemis Client object, adding
    # callbacks for the +execute+ method.
    module ClassMethods
      def inherited(klass) #:nodoc:
        super

        klass.callback_runner = Class.new(AbstractCallbackRunner)
      end

      # Defines a callback that will get called right before the
      # client's execute method is executed.
      #
      #   class VideoProcessJob < ActiveJob::Base
      #     queue_as :default
      #
      #     before_execute do |job|
      #       UserMailer.notify_video_started_processing(job.arguments.first)
      #     end
      #
      #     def execute(video_id)
      #       Video.find(video_id).process
      #     end
      #   end
      #
      def before_execute(*filters, &block)
        callback_runner.before_execute(*filters, &block)
      end

      # Defines a callback that will get called right after the
      # client's execute method has finished.
      #
      #   class VideoProcessJob < ActiveJob::Base
      #     queue_as :default
      #
      #     after_execute do |job|
      #       UserMailer.notify_video_processed(job.arguments.first)
      #     end
      #
      #     def execute(video_id)
      #       Video.find(video_id).process
      #     end
      #   end
      #
      def after_execute(*filters, &block)
        callback_runner.after_execute(*filters, &block)
      end
    end
  end

  class ContextProvider < SimpleDelegator
    def initialize(connection, callback_runner, default_context)
      super(connection)

      @callback_runner = callback_runner
      @default_context = default_context
    end

    def execute(document:, operation_name: nil, variables: {}, context: {})
      callback_runner = @callback_runner.new(document, operation_name, variables, @default_context.deep_merge(context))

      callback_runner.run_callbacks :execute do
        response = __getobj__.execute(
          document:          callback_runner.document,
          operation_name:    callback_runner.operation_name,
          variables:         callback_runner.variables,
          context:           callback_runner.context
        )
        callback_runner.response = response
        response
      end
    end
  end

  private_constant :ContextProvider

  class Client
    include Callbacks

    cattr_accessor :query_paths

    attr_reader :client

    def initialize(context = {})
      @client = self.class.instantiate_client(context)
    end

    class << self
      attr_writer :default_context

      def default_context
        @default_context ||= { }
      end

      def endpoint
        Artemis::GraphQLEndpoint.lookup(name)
      end

      def instantiate_client(context = {})
        ::GraphQL::Client.new(schema: endpoint.schema, execute: ContextProvider.new(endpoint.connection, callback_runner, context))
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
          ast     = instantiate_client.parse(graphql)

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

    def method_missing(method_name, context: {}, **arguments)
      if self.class.resolve_graphql_file_path(method_name)
        client.query(
          self.class.const_get(method_name.to_s.camelize),
          variables: arguments ? arguments.deep_transform_keys {|key| key.to_s.camelize(:lower) } : {},
          context: context
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
