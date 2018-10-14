describe GraphQL::Client do
  before do
    requests.clear
  end

  describe ".lookup_graphql_file" do
    it "returns the path to the matching graph file" do
      expect(Metaphysics.resolve_graphql_file_path("artist")).to eq("#{PROJECT_DIR}/spec/fixtures/metaphysics/artist.graphql")
    end

    it "returns nil if the file is missing" do
      expect(Metaphysics.resolve_graphql_file_path("does_not_exist")).to be_nil
    end
  end

  describe ".graphql_file_paths" do
    it "returns a list of GraphQL files (*.graphql) in the query_paths" do
      Metaphysics.instance_variable_set :@graphql_file_paths, nil
      original = Metaphysics.query_paths

      Metaphysics.query_paths = [File.join(PROJECT_DIR, 'tmp')]

      begin
        FileUtils.mkdir "./tmp/metaphysics" if !Dir.exist?("./tmp/metaphysics")

        with_files "./tmp/metaphysics/text.txt", "./tmp/metaphysics/sale.graphql" do
          expect(Metaphysics.graphql_file_paths).to eq(["#{PROJECT_DIR}/tmp/metaphysics/sale.graphql"])
        end
      ensure
        Metaphysics.instance_variable_set :@graphql_file_paths, nil
        Metaphysics.query_paths = original
      end
    end
  end

  it "can make a GraphQL request without variables" do
    Metaphysics.artwork

    request = requests[0]

    expect(request.operation_name).to eq('Metaphysics__Artwork')
    expect(request.variables).to be_empty
    expect(request.context).to eq({})
    expect(request.document.to_query_string).to eq(<<~GRAPHQL.strip)
      query Metaphysics__Artwork {
        artwork(id: "yayoi-kusama-pumpkin-yellow-and-black") {
          title
          artist {
            name
          }
        }
      }
    GRAPHQL
  end

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

  def with_files(*files)
    files.each {|file| FileUtils.touch(file) }
    yield
  ensure
    files.each {|file| File.delete(file) }
  end
end