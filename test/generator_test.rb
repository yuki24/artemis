require 'active_support/testing/autorun'
require 'rails/generators/test_case'

require 'generators/artemis/install_generator'

class GeneratorTest < Rails::Generators::TestCase
  tests Artemis::InstallGenerator
  arguments %w(metaphysics https://metaphysics-production.artsy.net)
  destination File.join(File.expand_path('../', File.dirname(__FILE__)), "tmp")
  setup :prepare_destination

  test "GraphQL client set up is done" do
    run_generator

    assert_file "app/operations/metaphysics.rb" do |client|
      assert_match(/class Metaphysics < Artemis::Client/, client)
    end

    assert_file "config/graphql.yml" do |yaml|
      assert_match(<<~YAML.strip, yaml)
        default: &default
          adapter: :net_http
          timeout: 10
          pool_size: 25

        development:
          metaphysics:
            <<: *default
            url: https://metaphysics-production.artsy.net

        test:
          metaphysics:
            <<: *default
            url: https://metaphysics-production.artsy.net

        production:
          metaphysics:
            <<: *default
            url: https://metaphysics-production.artsy.net
      YAML
    end

    assert_file "vendor/graphql/schema/metaphysics.json"
  end
end