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
    FileUtils.mkdir "#{app_path}/app/operations/github"
    FileUtils.touch "#{app_path}/app/operations/github/query.graphql"

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
          github:
            url: https://api.github.com/graphql
            adapter: :curb
            timeout: 5
            pool_size: 25
      YAML
    end

    FileUtils.mkdir_p "#{app_path}/vendor/graphql/schema"
    FileUtils.cp_r File.expand_path("spec/fixtures/github/schema.json"), "#{app_path}/vendor/graphql/schema/github.json"

    boot_rails

    endpoint = Artemis::GraphQLEndpoint.lookup(:github)

    assert endpoint.schema < GraphQL::Schema, "The schema does seem like a GraphQL::Schema object."
    assert_equal "https://api.github.com/graphql", endpoint.url
    assert_equal :curb,     endpoint.adapter
    assert_equal 5,         endpoint.timeout
    assert_equal 25,        endpoint.pool_size
  end

  test "test adapter does not require url" do
    File.open("#{app_path}/config/graphql.yml", "w") do |f|
      f.puts <<-YAML
        development:
          github:
            adapter: :test
      YAML
    end

    boot_rails

    endpoint = Artemis::GraphQLEndpoint.lookup(:github)

    assert_nil endpoint.url
    assert_not_nil endpoint.connection
    assert_equal :test, endpoint.adapter
  end

  test "test helper can load fixtures" do
    FileUtils.mkdir_p "#{app_path}/test/fixtures/graphql"
    FileUtils.touch "#{app_path}/test/fixtures/graphql/user.yml"

    File.open("#{app_path}/test/fixtures/graphql/user.yml", "w") do |f|
      f.puts <<-YAML
        yuki24:
          data:
            user:
              name: Yuki Nishijima
      YAML
    end

    require 'artemis/test_helper'
    boot_rails

    actual = Class.new { include Artemis::TestHelper }.new.stub_graphql('any', :user).send(:find_fixture_set)

    expected = {
      "yuki24" => {
        "data" => {
          "user" => {
            "name" => "Yuki Nishijima",
          }
        }
      }
    }

    assert_equal "user", actual.name
    assert_equal expected, actual.data
    assert actual.path.end_with?("test/fixtures/graphql/user.yml"),
           "Fixture path does not match:\n" \
           "  Expected: #{app_path}/test/fixtures/graphql/user.yml\n" \
           "  Actual:   #{actual.path}"
  end

  test "booting fails when the config/graphql.yml is malformed" do
    File.open("#{app_path}/config/graphql.yml", "w") do |f|
      f.puts <<-YAML
        development: github:
      YAML
    end

    error = assert_raises(RuntimeError) { boot_rails }

    assert_match "YAML syntax error occurred while parsing", error.message
  end

  test "adds a reloader that watches *.graphql files" do
    if Rails::VERSION::MAJOR >= 6
      skip "Skipping this test for Rails versions that work with Zeitwerk."
    end

    FileUtils.mkdir "#{app_path}/app/operations"
    FileUtils.mkdir "#{app_path}/app/operations/github"
    FileUtils.touch "#{app_path}/app/operations/github/query.graphql"

    File.open("#{app_path}/app/operations/github.rb", "w") do |f|
      f.puts <<-YAML
        class Github < Artemis::Client
        end
      YAML
    end

    boot_rails

    old_object_id = Github.object_id

    # The touch call simulates a file change and the get simulates a page reload.
    FileUtils.touch "#{app_path}/app/operations/github/query.graphql"
    get "/"

    assert_not_equal old_object_id, Github.object_id
  end

  test "preload the *.graphql files when eager_load is true and the app loader is set to :classic" do
    if Rails::VERSION::MAJOR >= 7
      skip "Skipping this test for Rails versions that work with Zeitwerk."
    end

    FileUtils.mkdir "#{app_path}/app/operations"
    FileUtils.mkdir "#{app_path}/app/operations/github"

    File.open("#{app_path}/config/graphql.yml", "w") do |f|
      f.puts <<-YAML
        development:
          github:
            url: https://api.github.com/graphql
            schema_path: spec/fixtures/github/schema.json
      YAML
    end

    File.open("#{app_path}/app/operations/github.rb", "w") do |f|
      f.puts <<-YAML
        class Github < Artemis::Client
        end
      YAML
    end

    File.open("#{app_path}/app/operations/github/user.graphql", "w") do |f|
      f.puts <<-GRAPHQL
        query($login: String!) {
          user(login: $login) {
            name
          }
        }
      GRAPHQL
    end

    add_to_config <<-RUBY
      config.autoloader = :classic
      config.cache_classes = true
      config.eager_load = true

      initializer 'add_middleware' do |app|
        app.config.middleware.use Rack::Head # Rack::Head is used only because it's almost always available
      end
    RUBY

    boot_rails

    assert defined?(Github), "Constant Github was not loaded"
    assert defined?(Github::User), "Constant Github::User was not loaded"
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
