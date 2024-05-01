require 'active_support/file_update_checker'

module Artemis
  class Railtie < ::Rails::Railtie #:nodoc:
    config.artemis = ActiveSupport::OrderedOptions.new
    config.artemis.query_path         = "app/operations"
    config.artemis.fixture_path       = "test/fixtures/graphql"
    config.artemis.schema_path        = "vendor/graphql/schema"
    config.artemis.graphql_extentions = ["graphql"]

    initializer 'graphql.client.attach_log_subscriber' do
      if !defined?(GraphQL::Client::LogSubscriber)
        require "graphql/client/log_subscriber"
        GraphQL::Client::LogSubscriber.attach_to :graphql
      end
    end

    initializer 'graphql.client.set_query_paths' do |app|
      query_path = config.artemis.query_path

      app.paths.add query_path

      Artemis::Client.query_paths = app.paths[query_path].existent
    end

    initializer 'graphql.test_helper' do |app|
      if !Rails.env.production?
        require 'artemis/test_helper'
        Artemis::TestHelper.__graphql_fixture_path__ = app.root.join(config.artemis.fixture_path)
      end
    end

    initializer 'graphql.client.set_reloader', after: 'graphql.client.set_query_paths' do |app|
      if !config.respond_to?(:autoloader) || config.autoloader != :zeitwerk
        files_to_watch = Artemis::Client.query_paths.map {|path| [path, config.artemis.graphql_extentions] }.to_h

        app.reloaders << ActiveSupport::FileUpdateChecker.new([], files_to_watch) do
          Artemis.config_for_graphql(app).each_key do |endpoint_name|
            Artemis::Client.query_paths.each do |path|
              FileUtils.touch("#{path}/#{endpoint_name}.rb") if File.exist?("#{path}/#{endpoint_name}.rb")
            end
          end
        end
      end
    end

    initializer 'graphql.client.load_config' do |app|
      if Pathname.new("#{app.paths["config"].existent.first}/graphql.yml").exist?
        Artemis.config_for_graphql(app).each do |endpoint_name, options|
          Artemis::GraphQLEndpoint
            .register!(
              endpoint_name,
              schema_path: app.root.join(config.artemis.schema_path, "#{endpoint_name}.json").to_s,
              **options.symbolize_keys
            )
        end
      end
    end

    initializer 'graphql.client.preload', after: 'graphql.client.load_config' do |app|
      if app.config.eager_load && app.config.cache_classes && (!config.respond_to?(:autoloader) || config.autoloader != :zeitwerk)
        Artemis::GraphQLEndpoint.registered_services.each do |endpoint_name|
          endpoint_name.camelize.constantize.preload!
        end
      end
    end

    rake_tasks do
      load "tasks/artemis.rake"
    end
  end
end
