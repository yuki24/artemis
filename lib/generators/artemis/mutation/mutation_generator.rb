# frozen_string_literal: true

require 'graphql/schema/finder'

class Artemis::MutationGenerator < Rails::Generators::Base
  source_root File.expand_path('../templates', __FILE__)

  argument :mutation_type,     type: :string, required: true,                banner: "Mutation type"
  argument :graphql_file_name, type: :string, required: false, default: nil, banner: "The name of the GraphQL file to be generated"

  class_option :service, type: :string, default: nil, aliases: "-A"

  def generate_mutation_file
    template "mutation.graphql", graphql_file_path
  end

  private

  def mutation_name
    mutation_type.underscore
  end

  def graphql_file_path
    "app/operations/#{service_name.underscore}/#{graphql_file_name.presence || mutation_name}.graphql"
  end

  def arguments
    target_mutation.arguments
  end

  def target_mutation
    schema.find("Mutation").fields[mutation_type] ||
      raise(GraphQL::Schema::Finder::MemberNotFoundError, "Could not find type `#{mutation_type}` in schema.")
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
             "  rails g artemis:mutation #{mutation_type} #{graphql_file_name} --service SERVICE"
      end
    end
  end
end
