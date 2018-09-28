describe GraphQL::Client do
  before do
    requests.clear
  end

  describe ".lookup_graphql_file" do
    it "returns the path to the matching graph file"
    it "raises an exception if the file is missing"
  end

  describe ".graphql_file_paths" do
    it "returns a list of GraphQL files (*.graphql) in the query_paths"
    it "raises an exception if query_paths is unset"
  end

  it "can make a GraphQL request without variables"

  it "can make a GraphQL request with variables" do
    Metaphysics.artist(id: "yayoi-kusama")

    request = requests[0]

    expect(request.operation_name).to eq('Metaphysics__Artist')
    expect(request.variables).to eq('id' => 'yayoi-kusama')
    expect(request.context).to eq({})
    expect(request.document.to_query_string).to eq(<<~GRAPHQL.strip)
      query Metaphysics__Artist($id: String!) {
        artist(id: $id) {
          name
          bio
          birthday
        }
      }
    GRAPHQL
  end

  it "can make a GraphQL request with a query that contains fragments"

  it "sets the parsed query to a constant" do
    Metaphysics.artist(id: "yayoi-kusama")

    expect(Metaphysics::Artist.document.to_query_string).to eq(<<~GRAPHQL.strip)
      query Metaphysics__Artist($id: String!) {
        artist(id: $id) {
          name
          bio
          birthday
        }
      }
    GRAPHQL
  end

  it "assigns context to the request when provided as an argument" do
    context = { headers: { Authorization: 'bearer ...' } }

    Metaphysics.artist(id: "yayoi-kusama", context: context)

    expect(requests[0].context).to eq(context)
  end

  it "can create a client that always assigns the provided context to the request" do
    context   = { headers: { Authorization: 'bearer ...' } }
    client    = Metaphysics.with_context(context)

    client.artist(id: "yayoi-kusama")
    client.artist(id: "yayoi-kusama")

    expect(requests[0].context).to eq(context)
    expect(requests[1].context).to eq(context)
  end

  it "assigns the default context to a GraphQL request if present" do
    begin
      Metaphysics.default_context = { headers: { Authorization: 'bearer ...' } }

      Metaphysics.artist(id: "yayoi-kusama")

      expect(requests[0].context).to eq(headers: { Authorization: 'bearer ...' })
    ensure
      Metaphysics.default_context = { }
    end
  end

  it "can make a GraphQL request with all of .default_context, with_context(...) and the :context argument" do
    begin
      Metaphysics.default_context = { headers: { 'User-Agent': 'Artemis', 'X-key': 'value', Authorization: 'token ...' } }
      Metaphysics
          .with_context({ headers: { 'X-key': 'overridden' } })
          .artist(id: "yayoi-kusama", context: { headers: { Authorization: 'bearer ...' } })

      expect(requests[0].context).to eq(
        headers: {
          'User-Agent': 'Artemis',
          'X-key': 'overridden',
          Authorization: 'bearer ...',
        }
      )
    ensure
      Metaphysics.default_context = { }
    end
  end

  private

  def requests
    Artemis::Adapters::TestAdapter.requests
  end
end