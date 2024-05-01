require_relative '../helpers/test_helper'
require 'rails/generators/test_case'

require 'generators/artemis/query/query_generator'

class QueryGeneratorTest < Rails::Generators::TestCase
  tests Artemis::QueryGenerator
  arguments %w(user)
  destination File.join(Dir.pwd, "tmp")
  setup :prepare_destination

  teardown do
    Artemis::GraphQLEndpoint.send(:const_get, :ENDPOINT_INSTANCES).delete('fake_service')
  end

  test "A new GraphQL file is created" do
    run_generator

    assert_file "app/operations/github/user.graphql" do |graphql|
      assert_match <<~GRAPHQL.strip, graphql
        query($login: String!) {
          user(login: $login) {
            # Add fields here...
          }
        }
      GRAPHQL
    end
  end

  test "A new fixture file for the query is created" do
    skip

    run_generator

    assert_file "test/fixtures/graphql/github/user.yml" do |fixture|
      puts 'aaaa'
      assert_match <<~GRAPHQL.strip, fixture
        # You can stub GraphQL queries by calling the `stub_graphql' method in test:
        #
        #   stub_graphql(Github, :user).to_return(:user_1)
        #
        # Or with a arguments matcher:
        #
        #   stub_graphql(Github, :user, login: "...").to_return(:user_2)
        #

        user_1:
          data:
            id: # type: String!
            name: # type: String!
      GRAPHQL
    end
  end

  test "A new GraphQL file is created with the name specified" do
    run_generator %w(user user_on_artwork)

    assert_file "app/operations/github/user_on_artwork.graphql" do |graphql|
      assert_match <<~GRAPHQL.strip, graphql
        query($login: String!) {
          user(login: $login) {
            # Add fields here...
          }
        }
      GRAPHQL
    end
  end

  test "Generating a query fails when service not specified and found multiple services" do
    Artemis::GraphQLEndpoint.register!(:fake_service, url: '')

    exception = assert_raises RuntimeError do
      run_generator %w(user user_on_artwork)
    end

    assert_match <<~MESSAGE.strip, exception.message
      Please specify a service name (available services: github, fake_service):

        rails g artemis:query user user_on_artwork --service SERVICE
    MESSAGE
  end

  test "A new GraphQL file is created with the name specified for the service specified" do
    Artemis::GraphQLEndpoint.register!(:fake_service, url: '')

    run_generator %w(user user_on_artwork --service Github)

    assert_file "app/operations/github/user_on_artwork.graphql" do |graphql|
      assert_match <<~GRAPHQL.strip, graphql
        query($login: String!) {
          user(login: $login) {
            # Add fields here...
          }
        }
      GRAPHQL
    end
  end
end
