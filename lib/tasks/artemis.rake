# frozen_string_literal: true

namespace :graphql do
  namespace :schema do
    desc "Downloads and saves the GraphQL schema (options: SERVICE=service_name AUTHORIZATION='token ...')"
    task update: :environment do
      service = if ENV['SERVICE']
                  ENV['SERVICE']
                else
                  services = Rails.application.config_for(:graphql).keys

                  if services.size == 1
                    services.first
                  else
                    raise "Please specify a service name (available services: #{services.join(", ")}): rake graphql:schema:update SERVICE=service"
                  end
                end

      headers = ENV['AUTHORIZATION'] ? { Authorization: ENV['AUTHORIZATION'] } : {}
      schema  = service.camelize.constantize.connection
                  .execute(
                    document: GraphQL::Client::IntrospectionDocument,
                    operation_name: "IntrospectionQuery",
                    variables: {},
                    context: { headers: headers }
                  ).to_h

      if schema['errors'].nil? || schema['errors'].empty?
        FileUtils.mkdir_p("vendor/graphql/schema/")
        File.open("vendor/graphql/schema/#{service.underscore}.json", 'w') do |file|
          file.write(JSON.pretty_generate(schema))
        end

        puts "saved schema to: vendor/graphql/schema/#{service.underscore}.json"
      else
        raise "received error from server: #{schema}\n\n"
      end
    end
  end
end