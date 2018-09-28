require 'integration_spec_helper'

describe "Integration with actual GraphQL server" do
  it "can make a GraphQL request" do
    response = Metaphysics.artist(id: "yayoi-kusama")

    artist = response.data.artist

    expect(artist.name).to eq("Yayoi Kusama")
    expect(artist.bio).to eq("Japanese, born 1929, Matsumoto City, Japan, based in Tokyo, Japan")
    expect(artist.birthday).to eq("1929")
  end
end