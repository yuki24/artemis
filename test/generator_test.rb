require 'isolated_test_helper'
require 'rails/generators/test_case'

require 'generators/artemis/install_generator'

class GeneratorTest < Rails::Generators::TestCase
  tests Artemis::InstallGenerator
  arguments %w(metaphysics https://metaphysics-production.artsy.net)
  destination File.join(File.expand_path('../', File.dirname(__FILE__)), "tmp")
  setup :prepare_destination

  test "GraphQL client set up is done" do
    stub_any_instance generator_class, instance: generator do |instance|
      mock = Minitest::Mock.new
      mock.expect(:call, nil, ["graphql:schema:update SERVICE=metaphysics"])

      instance.stub(:rake, mock) { run_generator }

      assert_mock mock
    end

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
  end

  test "GraphQL client set up is done with authorization" do
    stub_any_instance generator_class, instance: generator(default_arguments, { authorization: "token token" }) do |instance|
      mock = Minitest::Mock.new
      mock.expect(:call, nil, ["graphql:schema:update SERVICE=metaphysics AUTHORIZATION='token token'"])

      instance.stub(:rake, mock) { run_generator }

      assert_mock mock
    end
  end
end