describe GraphQL::Client do
  before do
    requests.clear
  end

  describe ".lookup_graphql_file" do
    it "returns the path to the matching graph file" do
      expect(Github.resolve_graphql_file_path("user")).to eq("#{PROJECT_DIR}/spec/fixtures/github/user.graphql")
    end

    it "returns nil if the file is missing" do
      expect(Github.resolve_graphql_file_path("does_not_exist")).to be_nil
    end
  end

  describe ".graphql_file_paths" do
    it "returns a list of GraphQL files (*.graphql) in the query_paths" do
      Github.instance_variable_set :@graphql_file_paths, nil
      original = Github.query_paths

      Github.query_paths = [File.join(PROJECT_DIR, 'tmp')]

      begin
        FileUtils.mkdir "./tmp/github" if !Dir.exist?("./tmp/github")

        with_files "./tmp/github/text.txt", "./tmp/github/sale.graphql" do
          expect(Github.graphql_file_paths).to eq(["#{PROJECT_DIR}/tmp/github/sale.graphql"])
        end
      ensure
        Github.instance_variable_set :@graphql_file_paths, nil
        Github.query_paths = original
      end
    end
  end

  it "can make a GraphQL request without variables" do
    Github.user

    request = requests[0]

    expect(request.operation_name).to eq('Github__User')
    expect(request.variables).to be_empty
    expect(request.context).to eq({})
    expect(request.document.to_query_string).to eq(<<~GRAPHQL.strip)
      query Github__User {
        user(login: "yuki24") {
          id
          name
        }
      }
    GRAPHQL
  end

  it "can make a GraphQL request with variables" do
    Github.repository(owner: "yuki24", name: "artemis")

    request = requests[0]

    expect(request.operation_name).to eq('Github__Repository')
    expect(request.variables).to eq("owner" => "yuki24", "name" => "artemis")
    expect(request.context).to eq({})
    expect(request.document.to_query_string).to eq(<<~GRAPHQL.strip)
      query Github__Repository($owner: String!, $name: String!) {
        repository(owner: $owner, name: $name) {
          name
          nameWithOwner
        }
      }
    GRAPHQL
  end

  it "can make a GraphQL request with a query that contains fragments" do
    Github.user_repositories(login: "yuki24", size: 10)

    request = requests[0]

    expect(request.operation_name).to eq('Github__UserRepositories')
    expect(request.variables).to eq('login' => 'yuki24', 'size' => 10)
    expect(request.context).to eq({})
    expect(request.document.to_query_string).to eq(<<~GRAPHQL.strip)
      query Github__UserRepositories($login: String!, $size: Int!) {
        user(login: $login) {
          id
          name
          repositories(first: $size) {
            nodes {
              name
              description
              ...Github__RepositoryFields
            }
          }
        }
      }

      fragment Github__RepositoryFields on Repository {
        name
        nameWithOwner
        url
        updatedAt
        languages(first: 1) {
          nodes {
            name
            color
          }
        }
      }
    GRAPHQL
  end

  it "can make a GraphQL request with #execute" do
    Github.execute(:repository, owner: "yuki24", name: "artemis")

    request = requests[0]

    expect(request.operation_name).to eq('Github__Repository')
    expect(request.variables).to eq("owner" => "yuki24", "name" => "artemis")
    expect(request.context).to eq({})
    expect(request.document.to_query_string).to eq(<<~GRAPHQL.strip)
      query Github__Repository($owner: String!, $name: String!) {
        repository(owner: $owner, name: $name) {
          name
          nameWithOwner
        }
      }
    GRAPHQL
  end

  it "raises an error when the specified graphql file does not exist" do
    expect { Github.execute(:does_not_exist) }
      .to raise_error(Artemis::GraphQLFileNotFound)
      .with_message(/Query does_not_exist\.graphql not found/)
  end

  it "assigns context to the request when provided as an argument" do
    context = { headers: { Authorization: 'bearer ...' } }

    Github.repository(owner: "yuki24", name: "artemis", context: context)

    expect(requests[0].context).to eq(context)
  end

  it "can create a client that always assigns the provided context to the request" do
    context   = { headers: { Authorization: 'bearer ...' } }
    client    = Github.with_context(context)

    client.repository(owner: "yuki24", name: "artemis")
    client.repository(owner: "yuki24", name: "artemis")

    expect(requests[0].context).to eq(context)
    expect(requests[1].context).to eq(context)
  end

  it "assigns the default context to a GraphQL request if present" do
    begin
      Github.default_context = { headers: { Authorization: 'bearer ...' } }
      Github.repository(owner: "yuki24", name: "artemis")

      expect(requests[0].context).to eq(headers: { Authorization: 'bearer ...' })
    ensure
      Github.default_context = { }
    end
  end

  it "can make a GraphQL request with all of .default_context, with_context(...) and the :context argument" do
    begin
      Github.default_context = { headers: { 'User-Agent': 'Artemis', 'X-key': 'value', Authorization: 'token ...' } }
      Github
          .with_context({ headers: { 'X-key': 'overridden' } })
          .repository(owner: "yuki24", name: "artemis", context: { headers: { Authorization: 'bearer ...' } })

      expect(requests[0].context).to eq(
        headers: {
          'User-Agent': 'Artemis',
          'X-key': 'overridden',
          Authorization: 'bearer ...',
        }
      )
    ensure
      Github.default_context = { }
    end
  end

  it "can batch multiple requests using Multiplex" do
    Github.multiplex do |queue|
      queue.repository(owner: "yuki24", name: "artemis", context: { headers: { Authorization: 'bearer ...' } })
      queue.user
    end

    repository_query, user_query = requests[0].queries

    expect(repository_query[:operationName]).to eq('Github__Repository')
    expect(repository_query[:variables]).to eq("owner" => "yuki24", "name" => "artemis")
    expect(repository_query[:context]).to eq({ headers: { Authorization: 'bearer ...' } })
    expect(repository_query[:query]).to eq(<<~GRAPHQL.strip)
      query Github__Repository($owner: String!, $name: String!) {
        repository(owner: $owner, name: $name) {
          name
          nameWithOwner
        }
      }
    GRAPHQL

    expect(user_query[:operationName]).to eq('Github__User')
    expect(user_query[:variables]).to be_empty
    expect(user_query[:context]).to eq({})
    expect(user_query[:query]).to eq(<<~GRAPHQL.strip)
      query Github__User {
        user(login: "yuki24") {
          id
          name
        }
      }
    GRAPHQL
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
