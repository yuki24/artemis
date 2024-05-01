require_relative 'helpers/test_helper'
require 'artemis/test_helper'

class TestHelperTest < ActiveSupport::TestCase
  include Artemis::TestHelper

  def graphql_fixture_path
    File.join(PROJECT_DIR, "test/fixtures/responses")
  end

  setup do
    graphql_requests.clear
    graphql_responses.clear
  end

  test "can mock a GraphQL request" do
    stub_graphql(Github, :repository).to_return(:yuki24_artemis)

    response = Github.repository(owner: "yuki24", name: "artemis")

    assert_equal "artemis", response.data.repository.name
    assert_equal "yuki24/artemis", response.data.repository.name_with_owner
  end

  test "can mock a GraphQL request with an ERB-enabled fixture" do
    stub_graphql(Github, :repository).to_return(:yuki24_rambulance)

    response = Github.repository(owner: "yuki24", name: "rambulance")

    assert_equal "yuki24/rambulance", response.data.repository.name_with_owner
  end

  test "can mock a GraphQL request with variables using exact match" do
    stub_graphql(Github, :repository, owner: "yuki24", name: "artemis").to_return(:yuki24_artemis)
    stub_graphql(Github, :repository, owner: "yuki24", name: "rambulance").to_return(:yuki24_rambulance)

    yuki24_artemis    = Github.repository(owner: "yuki24", name: "artemis")
    yuki24_rambulance = Github.repository(owner: "yuki24", name: "rambulance")

    assert_equal "artemis", yuki24_artemis.data.repository.name
    assert_equal "rambulance", yuki24_rambulance.data.repository.name
  end

  test "can mock a GraphQL request with a JSON file" do
    stub_graphql(Github, :user).to_return(:yuki24)

    response = Github.user

    assert_equal "foobar", response.data.user.id
    assert_equal "Yuki Nishijima", response.data.user.name
  end

  test "can mock a GraphQL request for a query that has a query name" do
    skip
  end

  test "raises an exception if the specified fixture file does not exist" do
    assert_raises Artemis::FixtureNotFound, match: %r|does_not_exist.{yml,json}| do
      stub_graphql(Github, :does_not_exist).to_return(:data)
    end
  end

  test "raises an exception if the specified fixture file exists but fixture key does not exist" do
    assert_raises Artemis::FixtureNotFound, match: %r|test/fixtures/responses/github/repository.yml| do
     stub_graphql(Github, :repository).to_return(:does_not_exist)
   end
  end

  test "picks up the fixture for the given service if multiple services have the exact same fixture" do
    stub_graphql(Github, :repository).to_return(:yoshiki)

    yoshiki = Github.repository(owner: "ruby", name: "did_you_mean")

    assert_equal "did_you_mean", yoshiki.data.repository.name
  end

  test "can mock separate GraphQL queries with the same arguments" do
    stub_graphql("SpotifyClient", :repository, id: "yoshiki").to_return(:yoshiki)
    stub_graphql(Github, :repository, id: "yoshiki").to_return(:yoshiki)

    yoshiki = Github.repository(id: "yoshiki")

    assert_equal "did_you_mean", yoshiki.data.repository.name
  end

  test "allows to get raw fixture data as a Hash" do
    actual = stub_graphql("SpotifyClient", :repository).get(:yoshiki)
    expected = {
      "data" => {
        "repository" => {
          "name" => "did_you_mean",
          "nameWithOwner" => "ruby/did_you_mean",
        }
      }
    }

    assert_equal expected, actual
  end
end
