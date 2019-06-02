# frozen_string_literal: true

require 'json'

require 'active_support/core_ext/string/inflections'
require 'graphql/client'

namespace :graphql do
  namespace :schema do
    desc "Downloads and saves the GraphQL schema (options: SERVICE=service_name AUTHORIZATION='token ...')"
    task update: :environment do
      service = if ENV['SERVICE']
                  ENV['SERVICE']
                else
                  services = Artemis.config_for_graphql(Rails.application).keys

                  if services.size == 1
                    services.first
                  else
                    raise "Please specify a service name (available services: #{services.join(", ")}): rake graphql:schema:update SERVICE=service"
                  end
                end

      headers          = ENV['AUTHORIZATION'] ? { Authorization: ENV['AUTHORIZATION'] } : {}
      service_class    = service.to_s.camelize.constantize
      schema_path      = service_class.endpoint.schema_path
      schema           = service_class.connection
                           .execute(
                             document: GraphQL::Client::IntrospectionDocument,
                             operation_name: "IntrospectionQuery",
                             variables: {},
                             context: { headers: headers }
                           ).to_h

      if schema['errors'].nil? || schema['errors'].empty?
        FileUtils.mkdir_p(File.dirname(schema_path))
        File.open(schema_path, 'w') do |file|
          file.write(JSON.pretty_generate(schema))
        end

        puts "saved schema to: #{schema_path.gsub("#{Dir.pwd}/", '')}"
      else
        raise "received error from server: #{schema}\n\n"
      end
    end
  end
end
