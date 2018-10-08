require "rack/test"
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

  test "loads graphql.yml and register endpoints" do
    File.open("#{app_path}/config/graphql.yml", "w") do |f|
      f.puts <<-YAML
        development:
          metaphysics:
            url: https://metaphysics-production.artsy.net
            adapter: :net_http
            timeout: 5
            pool_size: 25
      YAML
    end

    boot_rails

    endpoint = Artemis::GraphQLEndpoint.lookup(:metaphysics)

    assert_equal "https://metaphysics-production.artsy.net", endpoint.url
    assert_equal :net_http, endpoint.adapter
    assert_equal 5,         endpoint.timeout
    assert_equal 25,        endpoint.pool_size
  end

  test "adds a reloader that watches *.graphql files" do
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

    # Assuming that if the constant is removed the newly loaded constant won't have ref to the ivar.
    Metaphysics.instance_variable_set(:@retained, true)

    # The touch call simulates a file change and the get simulates a page reload.
    FileUtils.touch "#{app_path}/app/operations/metaphysics/query.graphql"
    get "/"

    assert_nil Metaphysics.instance_variable_get(:@retained)
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
      config.eager_load = true
    RUBY

    boot_rails

    assert defined?(Metaphysics),         "Constant Metaphysics was not loaded"
    assert defined?(Metaphysics::Artist), "Constant Metaphysics::Artist was not loaded"
  end

  private

  def app
    Rails.application
  end

  def boot_rails
    require "#{app_path}/config/environment"
  end
end