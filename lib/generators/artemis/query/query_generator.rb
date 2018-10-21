# frozen_string_literal: true

require 'graphql/schema/finder'

class Artemis::QueryGenerator < Rails::Generators::Base
  source_root File.expand_path('../templates', __FILE__)

  argument :query_type,        type: :string, required: true,                banner: "Query type"
  argument :graphql_file_name, type: :string, required: false, default: nil, banner: "The name of the GraphQL file to be generated"

  class_option :service, type: :string, default: nil, aliases: "-A"

  def generate_query_file
    template "query.graphql", graphql_file_path
  end

  private

  def query_name
    query_type.underscore
  end

  def graphql_file_path
    "app/operations/#{service_name.underscore}/#{graphql_file_name.presence || query_name}.graphql"
  end

  def arguments
    target_query.arguments
  end

  def target_query
    schema.find("Query").fields[query_type] ||
      raise(GraphQL::Schema::Finder::MemberNotFoundError, "Could not find type `#{query_type}` in schema.")
  end

  def schema
    service_name.camelize.constantize.endpoint.schema
  end

  def service_name
    options['service'].presence || begin
      services = Artemis::GraphQLEndpoint.registered_services

      if services.size == 1
        services.first
      else
        fail "Please specify a service name (available services: #{services.join(", ")}):\n\n" \
             "  rails g artemis:query #{query_type} #{graphql_file_name} --service SERVICE"
      end
    end
  end
end
