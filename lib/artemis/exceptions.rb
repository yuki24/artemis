module Artemis
  class Error < StandardError
  end

  class EndpointNotFound < Error
  end

  class ConfigurationError < Error
  end
end