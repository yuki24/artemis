require 'test_helper'
require 'rails/generators/test_case'

require 'generators/artemis/mutation/mutation_generator'

require_relative '../../spec/fixtures/github'

class MutationGeneratorTest < Rails::Generators::TestCase
  tests Artemis::MutationGenerator
  arguments %w(addStar)
  destination File.join(Dir.pwd, "tmp")
  setup :prepare_destination

  teardown do
    Artemis::GraphQLEndpoint.send(:const_get, :ENDPOINT_INSTANCES).delete('fake_service')
  end

  test "A new GraphQL file is created" do
    run_generator

    assert_file "app/operations/github/add_star.graphql" do |graphql|
      assert_match <<~GRAPHQL.strip, graphql
        mutation($input: AddStarInput!) {
          addStar(input: $input) {
            # Add fields here...
          }
        }
      GRAPHQL
    end
  end

  test "A new GraphQL file is created with the name specified" do
    run_generator %w(addStar add_star_2)

    assert_file "app/operations/github/add_star_2.graphql" do |graphql|
      assert_match <<~GRAPHQL.strip, graphql
        mutation($input: AddStarInput!) {
          addStar(input: $input) {
            # Add fields here...
          }
        }
      GRAPHQL
    end
  end

  test "Generating a mutation fails when ervice not specified and found multiple services" do
    Artemis::GraphQLEndpoint.register!(:fake_service, url: '')

    exception = assert_raises RuntimeError do
      run_generator %w(addStar add_star_2)
    end

    assert_match <<~MESSAGE.strip, exception.message
      Please specify a service name (available services: github, fake_service):

        rails g artemis:mutation addStar add_star_2 --service SERVICE
    MESSAGE
  end

  test "A new GraphQL file is created with the name specified for the service" do
    Artemis::GraphQLEndpoint.register!(:fake_service, url: '')

    run_generator %w(addStar add_star_2 --service Github)

    assert_file "app/operations/github/add_star_2.graphql" do |graphql|
      assert_match <<~GRAPHQL.strip, graphql
        mutation($input: AddStarInput!) {
          addStar(input: $input) {
            # Add fields here...
          }
        }
      GRAPHQL
    end
  end
end
