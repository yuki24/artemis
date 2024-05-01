require 'test_helper'

class GraphQLEndpointTest < ActiveSupport::TestCase
  teardown do
    Artemis::GraphQLEndpoint.const_get(:ENDPOINT_INSTANCES).delete("gitlab")
  end

  test ".lookup raises an exception when the service is missing" do
    assert_raises Artemis::EndpointNotFound do
      Artemis::GraphQLEndpoint.lookup(:does_not_exit)
    end
  end

  test "can register an endpoint" do
    endpoint = Artemis::GraphQLEndpoint.register!(:gitlab, url: "https://api.gitlab.com/graphql")

    assert_equal "https://api.gitlab.com/graphql", endpoint.url
    assert_instance_of Artemis::Adapters::NetHttpAdapter, endpoint.connection
  end

  test "can look up a registered endpoint" do
    Artemis::GraphQLEndpoint.register!(:gitlab, url: "https://api.gitlab.com/graphql")

    endpoint = Artemis::GraphQLEndpoint.lookup(:gitlab)

    assert_equal "https://api.gitlab.com/graphql", endpoint.url
    assert_instance_of Artemis::Adapters::NetHttpAdapter, endpoint.connection

    # FIXME: This #schema method makes a network call.
    # assert_equal ..., endpoint.schema
  end

  test "can register an endpoint with options" do
    options = {
      adapter: :test,
      timeout: 10,
      # schema_path: nil,
      pool_size: 25,
    }

    endpoint = Artemis::GraphQLEndpoint.register!(:gitlab, url: "https://api.gitlab.com/graphql", **options)

    assert_equal "https://api.gitlab.com/graphql", endpoint.url
    assert_equal 10, endpoint.timeout
    assert_equal 25, endpoint.pool_size
    assert_instance_of Artemis::Adapters::TestAdapter, endpoint.connection

    # FIXME: needs an example schema (and specify the :schema_path option) to test this.
    # assert_equal ..., endpoint.schema
  end
end