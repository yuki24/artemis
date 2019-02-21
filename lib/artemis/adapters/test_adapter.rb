# frozen_string_literal: true

require 'active_support/core_ext/module/attribute_accessors'

module Artemis
  module Adapters
    class TestAdapter
      cattr_accessor :requests
      self.requests = []

      cattr_accessor :responses
      self.responses = []

      Request = Struct.new(:document, :operation_name, :variables, :context)

      private_constant :Request

      def initialize(*)
      end

      # Main entry point for an Adapter, it receives the callbacks, set them and clears them after
      def call(document:, operation_name:, variables:, context: {}, callbacks: nil)
        @request_callbacks = callbacks
        result = execute(document: document, operation_name: operation_name, variables: variables, context: context)
        @request_callbacks = nil
        result
      end

      def execute(**arguments)
        self.requests << Request.new(*arguments.values_at(:document, :operation_name, :variables, :context))

        response = responses.detect do |mock|
          arguments[:operation_name] == mock.operation_name && mock.arguments == :__unspecified__ || arguments[:variables] == mock.arguments
        end

        response&.data || {
          'data' => { 'test' => 'data' },
          'errors' => [],
          'extensions' => {}
        }
      end
    end
  end
end
