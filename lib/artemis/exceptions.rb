module Artemis
  class Error < StandardError
  end

  class EndpointNotFound < Error
  end

  class ConfigurationError < Error
  end

  class GraphQLFileNotFound < Error
  end

  class FixtureNotFound < Error
  end

  class GraphQLError < Error
  end

  class GraphQLServerError < GraphQLError
  end
end