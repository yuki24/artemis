require 'artemis/test_helper'

RSpec.configure do |config|
  config.include ::Artemis::TestHelper

  config.before :each do
    graphql_requests.clear
    graphql_responses.clear
  end
end
