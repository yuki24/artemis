# frozen_string_literal: true

require "isolated_test_helper"

module ApplicationTests
  module RakeTests
    class RakeRoutesTest < ActiveSupport::TestCase
      include ActiveSupport::Testing::Isolation
      include Generation

      setup do
        build_app
        FileUtils.rm_rf "#{app_path}/config/environments"

        FileUtils.mkdir "#{app_path}/app/operations"
        File.open("#{app_path}/app/operations/metaphysics.rb", "w") do |f|
          f.puts <<-YAML
            class Metaphysics < Artemis::Client
            end
          YAML
        end
      end

      teardown do
        teardown_app
      end

      test "`rake graphql:schema:update` saves GraphQL schema to vendor/graphql/schema/service_name.json" do
        File.open("#{app_path}/config/graphql.yml", "w") do |f|
          f.puts <<-YAML
            development:
              metaphysics:
                url: http://localhost:8000
          YAML
        end

        assert_equal <<~MESSAGE, run_rake("graphql:schema:update")
          saved schema to: vendor/graphql/schema/metaphysics.json
        MESSAGE

        assert File.exist?("#{app_path}/vendor/graphql/schema/metaphysics.json"), "did not create vendor/graphql/schema/metaphysics.json"
      end

      test "`rake graphql:schema:update` respects the schema_path config in config/graphql.yml" do
        File.open("#{app_path}/config/graphql.yml", "w") do |f|
          f.puts <<-YAML
            development:
              metaphysics:
                url: http://localhost:8000
                schema_path: tmp/schema.json
          YAML
        end

        assert_equal <<~MESSAGE, run_rake("graphql:schema:update")
          saved schema to: tmp/schema.json
        MESSAGE

        assert File.exist?("#{app_path}/tmp/schema.json"), "did not create tmp/schema.json"
      end

      test "`rake graphql:schema:update` takes SERVICE argument" do
        File.open("#{app_path}/app/operations/github.rb", "w") do |f|
          f.puts <<-YAML
            class Github < Artemis::Client
            end
          YAML
        end

        File.open("#{app_path}/config/graphql.yml", "w") do |f|
          f.puts <<-YAML
            development:
              metaphysics:
                url: http://localhost:8000
              github:
                url: http://localhost:8000
          YAML
        end

        assert_equal <<~MESSAGE, run_rake("graphql:schema:update SERVICE=github")
          saved schema to: vendor/graphql/schema/github.json
        MESSAGE

        assert File.exist?("#{app_path}/vendor/graphql/schema/github.json"), "did not create vendor/graphql/schema/github.json"
      end

      test "`rake graphql:schema:update` takes AUTHORIZATION argument" do
        File.open("#{app_path}/config/graphql.yml", "w") do |f|
          f.puts <<-YAML
            development:
              metaphysics:
                url: http://localhost:8000
          YAML
        end

        assert_equal <<~MESSAGE, run_rake("graphql:schema:update AUTHORIZATION='token token'")
          saved schema to: vendor/graphql/schema/metaphysics.json
        MESSAGE

        assert File.exist?("#{app_path}/vendor/graphql/schema/metaphysics.json"), "did not create vendor/graphql/schema/metaphysics.json"

        body = open("#{app_path}/vendor/graphql/schema/metaphysics.json").read
        json = JSON.parse(body, symbolize_names: true)

        assert_equal 'token token', json[:data][:headers][:AUTHORIZATION]
      end

      # test "`rake graphql:schema:update` fails when there are two or more services but SERVICE_NAME is not specified" do
      #   FileUtils.mkdir "#{app_path}/app/operations"
      #   File.open("#{app_path}/app/operations/metaphysics.rb", "w") do |f|
      #     f.puts <<-YAML
      #       class Metaphysics < Artemis::Client
      #       end
      #     YAML
      #   end
      #
      #   File.open("#{app_path}/config/graphql.yml", "w") do |f|
      #     f.puts <<-YAML
      #       development:
      #         metaphysics:
      #           url: https://metaphysics-production.artsy.net
      #         github:
      #           url: https://api.github.com/graphql
      #     YAML
      #   end
      #
      #   run_rake("graphql:schema:update")
      #
      #   assert_equal <<~MESSAGE, run_rake("graphql:schema:update")
      #     Please specify a service name (available services: metaphysics, github): rake graphql:schema:update SERVICE=service
      #   MESSAGE
      #
      #   assert_not File.exist?("#{app_path}/vendor/graphql/schema/metaphysics.json"), "found vendor/graphql/schema/metaphysics.json when it should not"
      # end

      private

      def run_rake(task)
        Dir.chdir(app_path) { `bin/rake #{task}` }
      end
    end
  end
end