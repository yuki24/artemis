require 'date'

require 'active_support/core_ext/module/attribute_accessors'
require 'artemis/test_helper'

describe "#{GraphQL::Client} Callbacks" do
  Client = Class.new(Artemis::Client) do
    def self.name
      'Metaphysics'
    end

    mattr_accessor :before_callback, :after_callback
    self.before_callback = nil
    self.after_callback = nil

    before_execute do |document, operation_name, variables, context|
      self.before_callback = document, operation_name, variables, context
    end

    after_execute do |data, errors, extensions|
      self.after_callback = data, errors, extensions
    end
  end

  Spotify = Class.new(Artemis::Client) do
    def self.name
      'Spotify'
    end

    before_execute do
      raise "this callback should not get invoked"
    end

    after_execute do
      raise "this callback should not get invoked"
    end
  end

  describe ".before_execute" do
    it "gets invoked before executing" do
      Client.artist(id: 'yayoi-kusama', context: { user_id: 'yuki24' })

      document, operation_name, variables, context = Client.before_callback

      expect(document).to eq(Client::Artist.document)
      expect(operation_name).to eq('Client__Artist')
      expect(variables).to eq('id' => 'yayoi-kusama')
      expect(context).to eq(user_id: 'yuki24')
    end
  end

  describe ".after_execute" do
    include Artemis::TestHelper

    def graphql_fixture_path
      File.join(PROJECT_DIR, "spec/fixtures/responses")
    end

    it "gets invoked after executing" do
      stub_graphql(Client, :artwork).to_return(:the_last_supper)

      Client.artwork

      data, errors, extensions = Client.after_callback

      expect(data.artwork.title).to eq("The Last Supper")
      expect(errors.to_a).to eq([])
      expect(extensions).to eq({})

      expect {
        expect(data.key?('artwork')).to eq(true)
      }.to output("Hash access and related methods are deprecated. Please call the `respond_to?(artwork)' method instead.\n").to_stderr

      expect {
        expect(data['artwork']['title']).to eq("The Last Supper")
      }.to output("Hash access and related methods are deprecated. Please call a method `#artwork' instead.\n").to_stderr

      expect {
        expect(data.fetch('artwork').fetch('title')).to eq("The Last Supper")
      }.to output("Hash access and related methods are deprecated. Please call a method `#artwork' and use the || or safe operator instead.\n").to_stderr

      expect {
        expect(data.dig('artwork', 'title')).to eq("The Last Supper")
      }.to output("Hash access and related methods are deprecated. Please chain the calls `obj.artwork.title' instead.\n").to_stderr
    end
  end
end