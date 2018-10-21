require 'test_helper'
require 'rails/generators/test_case'

require 'generators/artemis/query/query_generator'

Artemis::GraphQLEndpoint.register!(:metaphysics, adapter: :test, url: '', schema_path: 'spec/fixtures/metaphysics/schema.json')
Artemis::GraphQLEndpoint.lookup(:metaphysics).load_schema!

require_relative '../../spec/fixtures/metaphysics'

class QueryGeneratorTest < Rails::Generators::TestCase
  tests Artemis::QueryGenerator
  arguments %w(artist)
  destination File.join(Dir.pwd, "tmp")
  setup :prepare_destination

  test "A new GraphQL file is created" do
    run_generator

    assert_file "app/operations/metaphysics/artist.graphql" do |graphql|
      assert_match <<~GRAPHQL.strip, graphql
        query($id: String!) {
          artist(id: $id) {
            # Add fields here...
          }
        }
      GRAPHQL
    end
  end
end

class QueryGeneratorWithFilenameTest < Rails::Generators::TestCase
  tests Artemis::QueryGenerator
  arguments %w(artist artist_on_artwork)
  destination File.join(Dir.pwd, "tmp")
  setup :prepare_destination

  teardown do
    Artemis::GraphQLEndpoint.send(:const_get, :ENDPOINT_INSTANCES).delete('fake_service')
  end

  test "A new GraphQL file is created with the name specified" do
    run_generator

    assert_file "app/operations/metaphysics/artist_on_artwork.graphql" do |graphql|
      assert_match <<~GRAPHQL.strip, graphql
        query($id: String!) {
          artist(id: $id) {
            # Add fields here...
          }
        }
      GRAPHQL
    end
  end

  test "Generating a query fails when ervice not specified and found multiple services" do
    Artemis::GraphQLEndpoint.register!(:fake_service, url: '')

    exception = assert_raises RuntimeError do
      run_generator
    end

    assert_match <<~MESSAGE.strip, exception.message
      Please specify a service name (available services: metaphysics, fake_service):

        rails g artemis:query artist artist_on_artwork --service SERVICE
    MESSAGE
  end
end

class QueryGeneratorWithServiceOptionTest < Rails::Generators::TestCase
  tests Artemis::QueryGenerator
  arguments %w(artist artist_on_artwork --service Metaphysics)
  destination File.join(Dir.pwd, "tmp")
  setup :prepare_destination

  test "A new GraphQL file is created with the name specified" do
    Artemis::GraphQLEndpoint.register!(:fake_service, url: '')

    run_generator

    assert_file "app/operations/metaphysics/artist_on_artwork.graphql" do |graphql|
      assert_match <<~GRAPHQL.strip, graphql
        query($id: String!) {
          artist(id: $id) {
            # Add fields here...
          }
        }
      GRAPHQL
    end
  end
end