require 'test_helper'
require 'rails/generators/test_case'

require 'generators/artemis/mutation/mutation_generator'

require_relative '../../spec/fixtures/metaphysics'

class MutationGeneratorTest < Rails::Generators::TestCase
  tests Artemis::MutationGenerator
  arguments %w(saveArtwork)
  destination File.join(Dir.pwd, "tmp")
  setup :prepare_destination

  teardown do
    Artemis::GraphQLEndpoint.send(:const_get, :ENDPOINT_INSTANCES).delete('fake_service')
  end

  test "A new GraphQL file is created" do
    run_generator

    assert_file "app/operations/metaphysics/save_artwork.graphql" do |graphql|
      assert_match <<~GRAPHQL.strip, graphql
        mutation($input: SaveArtworkInput!) {
          saveArtwork(input: $input) {
            # Add fields here...
          }
        }
      GRAPHQL
    end
  end

  test "A new GraphQL file is created with the name specified" do
    run_generator %w(saveArtwork save_artwork_on_top_page)

    assert_file "app/operations/metaphysics/save_artwork_on_top_page.graphql" do |graphql|
      assert_match <<~GRAPHQL.strip, graphql
        mutation($input: SaveArtworkInput!) {
          saveArtwork(input: $input) {
            # Add fields here...
          }
        }
      GRAPHQL
    end
  end

  test "Generating a mutation fails when ervice not specified and found multiple services" do
    Artemis::GraphQLEndpoint.register!(:fake_service, url: '')

    exception = assert_raises RuntimeError do
      run_generator %w(saveArtwork save_artwork_on_top_page)
    end

    assert_match <<~MESSAGE.strip, exception.message
      Please specify a service name (available services: metaphysics, fake_service):

        rails g artemis:mutation saveArtwork save_artwork_on_top_page --service SERVICE
    MESSAGE
  end

  test "A new GraphQL file is created with the name specified for the service" do
    Artemis::GraphQLEndpoint.register!(:fake_service, url: '')

    run_generator %w(saveArtwork save_artwork_on_top_page --service Metaphysics)

    assert_file "app/operations/metaphysics/save_artwork_on_top_page.graphql" do |graphql|
      assert_match <<~GRAPHQL.strip, graphql
        mutation($input: SaveArtworkInput!) {
          saveArtwork(input: $input) {
            # Add fields here...
          }
        }
      GRAPHQL
    end
  end
end
