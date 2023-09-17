require 'artemis/test_helper'
require 'date'

describe Artemis::TestHelper do
  include Artemis::TestHelper

  def graphql_fixture_path
    File.join(PROJECT_DIR, "spec/fixtures/responses")
  end

  before do
    graphql_requests.clear
    graphql_responses.clear
  end

  it "can mock a GraphQL request" do
    stub_graphql(Github, :repository).to_return(:yuki24_artemis)

    response = Github.repository(owner: "yuki24", name: "artemis")

    expect(response.data.repository.name).to eq("artemis")
    expect(response.data.repository.name_with_owner).to eq("yuki24/artemis")
  end

  it "can mock a GraphQL request with an ERB-enabled fixture" do
    stub_graphql(Github, :repository).to_return(:yuki24_rambulance)

    response = Github.repository(owner: "yuki24", name: "rambulance")

    expect(response.data.repository.name_with_owner).to eq("yuki24/rambulance")
  end

  it "can mock a GraphQL request with variables using exact match" do
    stub_graphql(Github, :repository, owner: "yuki24", name: "artemis").to_return(:yuki24_artemis)
    stub_graphql(Github, :repository, owner: "yuki24", name: "rambulance").to_return(:yuki24_rambulance)

    yuki24_artemis    = Github.repository(owner: "yuki24", name: "artemis")
    yuki24_rambulance = Github.repository(owner: "yuki24", name: "rambulance")

    expect(yuki24_artemis.data.repository.name).to eq("artemis")
    expect(yuki24_rambulance.data.repository.name).to eq("rambulance")
  end

  it "can mock a GraphQL request with a JSON file" do
    stub_graphql(Github, :user).to_return(:yuki24)

    response = Github.user

    expect(response.data.user.id).to eq("foobar")
    expect(response.data.user.name).to eq("Yuki Nishijima")
  end

  it "can mock a GraphQL request for a query that has a query name"

  it "raises an exception if the specified fixture file does not exist" do
    expect { stub_graphql(Github, :does_not_exist).to_return(:data) }
      .to raise_error(Artemis::FixtureNotFound, %r|does_not_exist.{yml,json}|)
  end

  it "raises an exception if the specified fixture file exists but fixture key does not exist" do
    expect { stub_graphql(Github, :repository).to_return(:does_not_exist) }
      .to raise_error(Artemis::FixtureNotFound, %r|spec/fixtures/responses/github/repository.yml|)
  end

  it "picks up the fixture for the given service if multiple services have the exact same fixture" do
    stub_graphql(Github, :repository).to_return(:yoshiki)

    yoshiki = Github.repository(owner: "ruby", name: "did_you_mean")

    expect(yoshiki.data.repository.name).to eq("did_you_mean")
  end

  it "can mock separate GraphQL queries with the same arguments" do
    stub_graphql("SpotifyClient", :repository, id: "yoshiki").to_return(:yoshiki)
    stub_graphql(Github, :repository, id: "yoshiki").to_return(:yoshiki)

    yoshiki = Github.repository(id: "yoshiki")
    
    expect(yoshiki.data.repository.name).to eq("did_you_mean")
  end

  it "allows to get raw fixture data as a Hash" do
    data = stub_graphql("SpotifyClient", :repository).get(:yoshiki)

    expect(data).to eq({
      "data" => {
        "repository" => {
          "name" => "did_you_mean",
          "nameWithOwner" => "ruby/did_you_mean",
        }
      }
    })
  end
end
