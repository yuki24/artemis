require 'test_helper'
require 'rails/generators/test_case'

require 'generators/artemis/install/install_generator'

class InstallGeneratorTest < Rails::Generators::TestCase
  tests Artemis::InstallGenerator
  arguments %w(metaphysics https://metaphysics-production.artsy.net)
  destination File.join(Dir.pwd, "tmp")
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
      assert_match 'adapter: :net_http', yaml
      assert_match 'timeout: 10', yaml
      assert_match 'pool_size: 25', yaml
      assert_match(<<~YAML.strip, yaml)
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

  test "GraphQL client set up is added to the existing config" do
    mkdir_p("#{destination_root}/config")
    File.open("#{destination_root}/config/graphql.yml", "w") do |f|
      f.puts <<~YAML
        development:
          github:
            <<: *default
            url: https://api.github.com/graphql

        test:

        production:
      YAML
    end

    stub_any_instance generator_class, instance: generator do |instance|
      instance.stub(:rake, Minitest::Mock.new) { run_generator }
    end

    assert_file "config/graphql.yml" do |yaml|
      assert_match(<<~YAML.strip, yaml)
        development:
          metaphysics:
            <<: *default
            url: https://metaphysics-production.artsy.net

          github:
            <<: *default
            url: https://api.github.com/graphql
      YAML

      assert_match(<<~YAML.strip, yaml)
        test:
          metaphysics:
            <<: *default
            url: https://metaphysics-production.artsy.net
      YAML

      assert_match(<<~YAML.strip, yaml)
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

  def assert_mock(mock)
    assert mock.verify
  end if !respond_to?(:assert_mock)
end
