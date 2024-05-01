require 'test_helper'

class ClientTest < ActiveSupport::TestCase
  setup do
    requests.clear
  end

  test ".lookup_graphql_file returns the path to the matching graph file" do
    assert_equal "#{PROJECT_DIR}/spec/fixtures/github/user.graphql", Github.resolve_graphql_file_path("user")
  end

  test ".lookup_graphql_file returns nil if the file is missing" do
    assert_nil Github.resolve_graphql_file_path("does_not_exist")
  end

  test ".graphql_file_paths returns a list of GraphQL files (*.graphql) in the query_paths" do
    Github.instance_variable_set :@graphql_file_paths, nil
    original = Github.query_paths

    Github.query_paths = [File.join(PROJECT_DIR, 'tmp')]

    begin
      FileUtils.mkdir "./tmp/github" if !Dir.exist?("./tmp/github")

      with_files "./tmp/github/text.txt", "./tmp/github/sale.graphql" do
        assert_equal ["#{PROJECT_DIR}/tmp/github/sale.graphql"], Github.graphql_file_paths
      end
    ensure
      Github.instance_variable_set :@graphql_file_paths, nil
      Github.query_paths = original
    end
  end

  test "can make a GraphQL request without variables" do
    Github.user

    request = requests[0]

    assert_equal 'Github__User', request.operation_name
    assert_empty request.variables
    assert_equal({}, request.context)
    assert_equal <<~GRAPHQL.strip, request.document.to_query_string
      query Github__User {
        user(login: "yuki24") {
          id
          name
        }
      }
    GRAPHQL
  end

  test "can make a GraphQL request with variables" do
    Github.repository(owner: "yuki24", name: "artemis")

    request = requests[0]

    assert_equal 'Github__Repository', request.operation_name
    assert_equal({ "owner" => "yuki24", "name" => "artemis" }, request.variables)
    assert_equal({}, request.context)
    assert_equal <<~GRAPHQL.strip, request.document.to_query_string
      query Github__Repository($owner: String!, $name: String!) {
        repository(owner: $owner, name: $name) {
          name
          nameWithOwner
        }
      }
    GRAPHQL
  end

  test "can make a GraphQL request with a query that contains fragments" do
    Github.user_repositories(login: "yuki24", size: 10)

    request = requests[0]

    assert_equal 'Github__UserRepositories', request.operation_name
    assert_equal({ 'login' => 'yuki24', 'size' => 10 }, request.variables)
    assert_equal({}, request.context)
    assert_equal <<~GRAPHQL.strip, request.document.to_query_string
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

  test "can make a GraphQL request with #execute" do
    Github.execute(:repository, owner: "yuki24", name: "artemis")

    request = requests[0]

    assert_equal 'Github__Repository', request.operation_name
    assert_equal({ "owner" => "yuki24", "name" => "artemis" }, request.variables)
    assert_equal({}, request.context)
    assert_equal <<~GRAPHQL.strip, request.document.to_query_string
      query Github__Repository($owner: String!, $name: String!) {
        repository(owner: $owner, name: $name) {
          name
          nameWithOwner
        }
      }
    GRAPHQL
  end

  test "raises an error when the specified graphql file does not exist" do
    assert_raises Artemis::GraphQLFileNotFound, match: /Query does_not_exist\.graphql not found/ do
      Github.execute(:does_not_exist)
    end
  end

  test "assigns context to the request when provided as an argument" do
    context = { headers: { Authorization: 'bearer ...' } }

    Github.repository(owner: "yuki24", name: "artemis", context: context)

    assert_equal context, requests[0].context
  end

  test "can create a client that always assigns the provided context to the request" do
    context   = { headers: { Authorization: 'bearer ...' } }
    client    = Github.with_context(context)

    client.repository(owner: "yuki24", name: "artemis")
    client.repository(owner: "yuki24", name: "artemis")

    assert_equal context, requests[0].context
    assert_equal context, requests[1].context
  end

  test "assigns the default context to a GraphQL request if present" do
    begin
      Github.default_context = { headers: { Authorization: 'bearer ...' } }
      Github.repository(owner: "yuki24", name: "artemis")

      assert_equal({ headers: { Authorization: 'bearer ...' } }, requests[0].context)
    ensure
      Github.default_context = { }
    end
  end

  test "can make a GraphQL request with all of .default_context, with_context(...) and the :context argument" do
    begin
      Github.default_context = { headers: { 'User-Agent': 'Artemis', 'X-key': 'value', Authorization: 'token ...' } }
      Github
          .with_context({ headers: { 'X-key': 'overridden' } })
          .repository(owner: "yuki24", name: "artemis", context: { headers: { Authorization: 'bearer ...' } })

      expected = {
        headers: {
          'User-Agent': 'Artemis',
          'X-key': 'overridden',
          Authorization: 'bearer ...',
        }
      }

      assert_equal expected, requests[0].context
    ensure
      Github.default_context = { }
    end
  end

  test "can batch multiple requests using Multiplex" do
    Github.multiplex do |queue|
      queue.repository(owner: "yuki24", name: "artemis", context: { headers: { Authorization: 'bearer ...' } })
      queue.user
    end

    repository_query, user_query = requests[0].queries

    assert_equal 'Github__Repository', repository_query[:operationName]
    assert_equal({ "owner" => "yuki24", "name" => "artemis" }, repository_query[:variables])
    assert_equal({ headers: { Authorization: 'bearer ...' } }, repository_query[:context])
    assert_equal <<~GRAPHQL.strip, repository_query[:query]
      query Github__Repository($owner: String!, $name: String!) {
        repository(owner: $owner, name: $name) {
          name
          nameWithOwner
        }
      }
    GRAPHQL

    assert_equal 'Github__User', user_query[:operationName]
    assert_empty user_query[:variables]
    assert_equal({}, user_query[:context])
    assert_equal <<~GRAPHQL.strip, user_query[:query]
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
