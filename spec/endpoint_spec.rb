describe Artemis::GraphQLEndpoint do
  describe ".lookup" do
    it "raises an exception when the service is missing" do
      expect { Artemis::GraphQLEndpoint.lookup(:does_not_exit) }.to raise_error(Artemis::EndpointNotFound)
    end
  end

  it "can register an endpoint" do
    endpoint = Artemis::GraphQLEndpoint.register!(:github, url: "https://api.github.com/graphql")

    expect(endpoint.url).to eq("https://api.github.com/graphql")
    expect(endpoint.connection).to be_instance_of(Artemis::Adapters::NetHttpAdapter)
  end

  it "can look up a registered endpoint" do
    Artemis::GraphQLEndpoint.register!(:github, url: "https://api.github.com/graphql")

    endpoint = Artemis::GraphQLEndpoint.lookup(:github)

    expect(endpoint.url).to eq("https://api.github.com/graphql")
    expect(endpoint.connection).to be_instance_of(Artemis::Adapters::NetHttpAdapter) # Not a fan of this test but for now

    # FIXME: This #schema method makes a network call.
    # expect(endpoint.schema).to eq(...)
  end

  it "can register an endpoint with options" do
    options = {
      adapter: :test,
      timeout: 10,
      # schema_path: nil,
      pool_size: 25,
    }

    endpoint = Artemis::GraphQLEndpoint.register!(:github, url: "https://api.github.com/graphql", **options)

    expect(endpoint.url).to eq("https://api.github.com/graphql")
    expect(endpoint.timeout).to eq(10)
    expect(endpoint.pool_size).to eq(25)
    expect(endpoint.connection).to be_instance_of(Artemis::Adapters::TestAdapter) # Not a fan of this test but for now

    # FIXME: needs an example schema (and specify the :schema_path option) to test this.
    # expect(endpoint.schema).to eq(...)
  end
end