require 'active_support/file_update_checker'

module Artemis
  class Railtie < ::Rails::Railtie #:nodoc:
    initializer 'graphql.client.attach_log_subscriber' do
      if !defined?(GraphQL::Client::LogSubscriber)
        require "graphql/client/log_subscriber"
        GraphQL::Client::LogSubscriber.attach_to :graphql
      end
    end

    initializer 'graphql.client.set_query_paths' do |app|
      app.paths.add "app/operations"

      Artemis::Client.query_paths = app.paths["app/operations"].existent
    end

    initializer 'graphql.client.set_reloader', after: 'graphql.client.set_query_paths' do |app|
      files_to_watch = Artemis::Client.query_paths.map {|path| [path, ["graphql"]] }.to_h
      endpoint_names = app.config_for(:graphql).keys

      app.reloaders << ActiveSupport::FileUpdateChecker.new([], files_to_watch) do
        endpoint_names.each do |endpoint_name|
          Artemis::Client.query_paths.each do |path|
            FileUtils.touch("#{path}/#{endpoint_name}.rb")
          end
        end
      end
    end

    initializer 'graphql.client.load_config' do |app|
      app.config_for(:graphql).each do |endpoint_name, options|
        Artemis::GraphQLEndpoint.register!(endpoint_name, options)
      end
    end

    # TODO: preload GraphQL files in production
    # initializer 'graphql.preload', after: :eager_load! do
    #   if Rails.env.production?
    #
    #   end
    # end
  end
end