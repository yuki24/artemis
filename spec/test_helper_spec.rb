require 'artemis/test_helper'

describe GraphQL::Client do
  include Artemis::TestHelper

  def graphql_fixture_path
    File.join(PROJECT_DIR, "spec/fixtures/responses")
  end

  before do
    graphql_requests.clear
    graphql_responses.clear
  end

  it "can mock a GraphQL request" do
    stub_graphql(Metaphysics, :artist).to_return(:yayoi_kusama)

    response = Metaphysics.artist(id: "yayoi-kusama")

    expect(response.data.artist.name).to eq("Yayoi Kusama")
    expect(response.data.artist.birthday).to eq("1929/03/22")
  end

  it "can mock a GraphQL request with variables using exact match" do
    stub_graphql(Metaphysics, :artist, id: "yayoi-kusama").to_return(:yayoi_kusama)
    stub_graphql(Metaphysics, :artist, id: "leonardo-da-vinci").to_return(:leonardo_da_vinci)

    yayoi_kusama = Metaphysics.artist(id: "yayoi-kusama")
    da_vinci     = Metaphysics.artist(id: "leonardo-da-vinci")

    expect(yayoi_kusama.data.artist.name).to eq("Yayoi Kusama")
    expect(da_vinci.data.artist.name).to eq("Leonardo da Vinci")
  end

  it "can mock a GraphQL request with a JSON file" do
    stub_graphql(Metaphysics, :artwork).to_return(:the_last_supper)

    response = Metaphysics.artwork(id: "leonardo-da-vinci-the-last-supper")

    expect(response.data.artwork.title).to eq("The Last Supper")
    expect(response.data.artwork.artist.name).to eq("Leonardo da Vinci")
  end

  it "can mock a GraphQL request for a query that has a query name"

  it "raises an exception if the specified fixture file does not exist" do
    expect { stub_graphql(Metaphysics, :does_not_exist) }
      .to raise_error(Artemis::FixtureNotFound, %r|spec/fixtures/responses/does_not_exist.{yml,json}|)
  end

  it "raises an exception if the specified fixture file exists but fixture key does not exist" do
    expect { stub_graphql(Metaphysics, :artist).to_return(:does_not_exist) }
      .to raise_error(Artemis::FixtureNotFound, %r|spec/fixtures/responses/artist.yml|)
  end
end
