# frozen-string-literal: true

require 'active_support/dependencies/autoload'

module Artemis
  module Adapters
    extend ActiveSupport::Autoload

    autoload :NetHttpAdapter
    # autoload :NetHttpPersistentAdapter

    class << self
      ##
      # Returns the constant for the specified adapter name.
      #
      #   Artemis::Adapters.lookup(:net_http)
      #   # => Artemis::Adapters::NetHttpAdapter
      def lookup(name)
        const_get("#{name.to_s.camelize}Adapter")
      end
    end
  end
end
