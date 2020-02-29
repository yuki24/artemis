require 'test_helper'
require 'rails/generators/test_case'

require 'generators/artemis/query/query_generator'

require_relative '../../spec/fixtures/metaphysics'

class QueryGeneratorTest < Rails::Generators::TestCase
  tests Artemis::QueryGenerator
  arguments %w(artist)
  destination File.join(Dir.pwd, "tmp")
  setup :prepare_destination

  teardown do
    Artemis::GraphQLEndpoint.send(:const_get, :ENDPOINT_INSTANCES).delete('fake_service')
  end

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

  test "A new fixture file for the query is created" do
    run_generator

    assert_file "test/fixtures/graphql/metaphysics/artist.yml" do |fixture|
      assert_match <<~GRAPHQL.strip, fixture
        # You can stub GraphQL queries by calling the `stub_graphql' method in test:
        #
        #   stub_graphql(Metaphysics, :artist).to_return(:artist_1)
        #
        # Or with a arguments matcher:
        #
        #   stub_graphql(Metaphysics, :artist, id: "...").to_return(:artist_2)
        #

        artist_1:
          data:
            __id: # type: ID!
            id: # type: String!
            _id: # type: String!
            cached: # type: Int
            alternate_names: # type: [String]
            articlesConnection: # type: ArticleConnection
            articles: # type: [Article]
            artists: # type: [Artist]
            artworks: # type: [Artwork]
            artworks_connection: # type: ArtworkConnection
            auctionResults: # type: AuctionResultConnection
            bio: # type: String
            biography: # type: Article
            biography_blurb: # type: ArtistBlurb
            birthday: # type: String
            blurb: # type: String
            carousel: # type: ArtistCarousel
            collections: # type: [String]
            contemporary: # type: [Artist]
            consignable: # type: Boolean
            counts: # type: ArtistCounts
            currentEvent: # type: CurrentEvent
            deathday: # type: String
            display_auction_link: # type: Boolean
            exhibition_highlights: # type: [Show]
            filtered_artworks: # type: FilterArtworks
            formatted_artworks_count: # type: String
            formatted_nationality_and_birthday: # type: String
            genes: # type: [Gene]
            gender: # type: String
            href: # type: String
            has_metadata: # type: Boolean
            hometown: # type: String
            image: # type: Image
            initials: # type: String
            is_consignable: # type: Boolean
            is_display_auction_link: # type: Boolean
            is_followed: # type: Boolean
            is_public: # type: Boolean
            is_shareable: # type: Boolean
            location: # type: String
            meta: # type: ArtistMeta
            nationality: # type: String
            name: # type: String
            partners: # type: PartnerArtistConnection
            partner_artists: # type: [PartnerArtist]
            partner_shows: # type: [PartnerShow]
            public: # type: Boolean
            related: # type: ArtistRelatedData
            sales: # type: [Sale]
            shows: # type: [Show]
            showsConnection: # type: ShowConnection
            sortable_id: # type: String
            statuses: # type: ArtistStatuses
            highlights: # type: ArtistHighlights
            years: # type: String
      GRAPHQL
    end
  end

  test "A new GraphQL file is created with the name specified" do
    run_generator %w(artist artist_on_artwork)

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

  test "Generating a query fails when service not specified and found multiple services" do
    Artemis::GraphQLEndpoint.register!(:fake_service, url: '')

    exception = assert_raises RuntimeError do
      run_generator %w(artist artist_on_artwork)
    end

    assert_match <<~MESSAGE.strip, exception.message
      Please specify a service name (available services: metaphysics, fake_service):

        rails g artemis:query artist artist_on_artwork --service SERVICE
    MESSAGE
  end

  test "A new GraphQL file is created with the name specified for the service specified" do
    Artemis::GraphQLEndpoint.register!(:fake_service, url: '')

    run_generator %w(artist artist_on_artwork --service Metaphysics)

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
