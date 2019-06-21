module Artemis
  class Configuration
    # The paths in which the Artemis client looks for files that have the +.graphql+ extension.
    # In a rails app, this value will be set to +["app/operations"]+ by Artemis' +Artemis::Railtie+.
    attr_accessor :query_paths

    # Default context that is appended to every GraphQL request for the client.
    attr_accessor :default_context

    # List of before callbacks that get invoked in every +execute+ call.
    #
    # @api  private
    attr_accessor :before_callbacks

    # List of after callbacks that get invoked in every +execute+ call.
    #
    # @api private
    attr_accessor :after_callbacks

    def initialize
      @query_paths = []
      @default_context = {}
      @before_callbacks = []
      @after_callbacks = []
    end
  end
end
