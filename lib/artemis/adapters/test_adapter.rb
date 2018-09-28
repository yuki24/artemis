# frozen_string_literal: true

module Artemis
  module Adapters
    class TestAdapter
      cattr_accessor :requests
      self.requests = []

      Request = Struct.new(:document, :operation_name, :variables, :context)

      private_constant :Request

      def initialize(*)
      end

      def execute(**arguments)
        self.requests << Request.new(*arguments.values_at(:document, :operation_name, :variables, :context))

        {
          data: {},
          errors: {}
        }
      end
    end
  end
end
