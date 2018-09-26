module Artemis
  class Railtie < ::Rails::Railtie #:nodoc:
    # TODO: load config/graphql.yml and instantiate endpoint objects
    # initializer 'graphql.load_config' do
    #   app.config_for(:metaphysics).each do |service_name, config|
    #     Artemis::GraphQLEndpoint.register!(service_name, config)
    #   end
    # end

    # TODO: preload GraphQL files in production
    # initializer 'graphql.preload', after: :eager_load! do
    #   if Rails.env.production?
    #
    #   end
    # end
  end
end