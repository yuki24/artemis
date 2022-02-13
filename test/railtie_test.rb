require "rack/test"
require "rails/version"
require "isolated_test_helper"

class RailtieTest < ActiveSupport::TestCase
  include ActiveSupport::Testing::Isolation
  include Rack::Test::Methods
  include Generation

  setup do
    build_app
    FileUtils.rm_rf "#{app_path}/config/environments"
  end

  teardown do
    teardown_app
  end

  test "sets query paths" do
    FileUtils.mkdir "#{app_path}/app/operations"
    FileUtils.mkdir "#{app_path}/app/operations/metaphysics"
    FileUtils.touch "#{app_path}/app/operations/metaphysics/query.graphql"

    add_to_config <<-RUBY
      config.root = "#{app_path}"
    RUBY

    boot_rails

    expanded_path = File.expand_path("app/operations", app_path)
    assert_equal [expanded_path], Artemis::Client.query_paths
  end

  test "loads GraphQL schema from vendor/graphql/schema/service_name.json" do
    File.open("#{app_path}/config/graphql.yml", "w") do |f|
      f.puts <<-YAML
        development:
          metaphysics:
            url: https://metaphysics-production.artsy.net
            adapter: :curb
            timeout: 5
            pool_size: 25
      YAML
    end

    FileUtils.mkdir_p "#{app_path}/vendor/graphql/schema"
    FileUtils.cp_r File.expand_path("spec/fixtures/metaphysics/schema.json"), "#{app_path}/vendor/graphql/schema/metaphysics.json"

    boot_rails

    endpoint = Artemis::GraphQLEndpoint.lookup(:metaphysics)

    assert endpoint.schema < GraphQL::Schema, "The schema does seem like a GraphQL::Schema object."
    assert_equal "https://metaphysics-production.artsy.net", endpoint.url
    assert_equal :curb,     endpoint.adapter
    assert_equal 5,         endpoint.timeout
    assert_equal 25,        endpoint.pool_size
  end

  test "test adapter does not require url" do
    File.open("#{app_path}/config/graphql.yml", "w") do |f|
      f.puts <<-YAML
        development:
          metaphysics:
            adapter: :test
      YAML
    end

    boot_rails

    endpoint = Artemis::GraphQLEndpoint.lookup(:metaphysics)

    assert_nil endpoint.url
    assert_not_nil endpoint.connection
    assert_equal :test, endpoint.adapter
  end

  test "test helper can load fixtures" do
    FileUtils.mkdir_p "#{app_path}/test/fixtures/graphql"
    FileUtils.touch "#{app_path}/test/fixtures/graphql/artist.yml"

    File.open("#{app_path}/test/fixtures/graphql/artist.yml", "w") do |f|
      f.puts <<-YAML
        leonardo_da_vinci:
          data:
            artist:
              name: Leonardo da Vinci
      YAML
    end

    require 'artemis/test_helper'
    boot_rails

    actual = Class.new { include Artemis::TestHelper }.new.stub_graphql('any', :artist).send(:find_fixture_set)

    expected = {
      "leonardo_da_vinci" => {
        "data" => {
          "artist" => {
            "name" => "Leonardo da Vinci",
          }
        }
      }
    }

    assert_equal "artist", actual.name
    assert_equal expected, actual.data
    assert actual.path.end_with?("test/fixtures/graphql/artist.yml"),
           "Fixture path does not match:\n" \
           "  Expected: #{app_path}/test/fixtures/graphql/artist.yml\n" \
           "  Actual:   #{actual.path}"
  end

  test "booting fails when the config/graphql.yml is malformed" do
    File.open("#{app_path}/config/graphql.yml", "w") do |f|
      f.puts <<-YAML
        development: metaphysics:
      YAML
    end

    error = assert_raises(RuntimeError) { boot_rails }

    assert_match "YAML syntax error occurred while parsing", error.message
  end

  test "adds a reloader that watches *.graphql files" do
    if Rails::VERSION::MAJOR >= 6
      skip "For some reason auto-reloading fails in Rails >= 6 but it works in a real app"
    end

    FileUtils.mkdir "#{app_path}/app/operations"
    FileUtils.mkdir "#{app_path}/app/operations/metaphysics"
    FileUtils.touch "#{app_path}/app/operations/metaphysics/query.graphql"

    File.open("#{app_path}/app/operations/metaphysics.rb", "w") do |f|
      f.puts <<-YAML
        class Metaphysics < Artemis::Client
        end
      YAML
    end

    boot_rails

    old_object_id = Metaphysics.object_id

    # The touch call simulates a file change and the get simulates a page reload.
    FileUtils.touch "#{app_path}/app/operations/metaphysics/query.graphql"
    get "/"

    assert_not_equal old_object_id, Metaphysics.object_id
  end

  test "preload the *.graphql files when eager_load is true" do
    FileUtils.mkdir "#{app_path}/app/operations"
    FileUtils.mkdir "#{app_path}/app/operations/metaphysics"

    File.open("#{app_path}/config/graphql.yml", "w") do |f|
      f.puts <<-YAML
        development:
          metaphysics:
            url: https://metaphysics-production.artsy.net
            schema_path: spec/fixtures/metaphysics/schema.json
      YAML
    end

    File.open("#{app_path}/app/operations/metaphysics.rb", "w") do |f|
      f.puts <<-YAML
        class Metaphysics < Artemis::Client
        end
      YAML
    end

    File.open("#{app_path}/app/operations/metaphysics/artist.graphql", "w") do |f|
      f.puts <<-GRAPHQL
        query($id: String!) {
          artist(id: $id) {
            name
          }
        }
      GRAPHQL
    end

    add_to_config <<-RUBY
      config.cache_classes = true
      config.eager_load = true

      initializer 'add_middleware' do |app|
        app.config.middleware.use Rack::Head # Rack::Head is used just because it's almost always available
      end
    RUBY

    boot_rails

    assert defined?(Metaphysics),         "Constant Metaphysics was not loaded"
    assert defined?(Metaphysics::Artist), "Constant Metaphysics::Artist was not loaded"
  end

  test "avoid crashing when eager_load is true but without config/graphql.yml" do
    add_to_config <<-RUBY
      config.cache_classes = true
      config.eager_load = true
    RUBY

    assert_nothing_raised {
      boot_rails
    }
  end

  private

  def app
    Rails.application
  end

  def boot_rails
    require "#{app_path}/config/environment"
  end
end
