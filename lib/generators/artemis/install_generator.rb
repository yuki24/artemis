require 'graphql/client'
require 'graphql/client/http'

class Artemis::InstallGenerator < Rails::Generators::NamedBase
  source_root File.expand_path('../templates', __FILE__)

  argument :endpoint_url, type: :string, banner: "The endpoint URL for a GraphQL service"

  class_option :authorization, type: :string, default: nil, aliases: "-A"

  def generate_client
    template "client.rb", client_file_name
    create_file query_dir_gitkeep, ""
  end

  def generate_config
    in_root do
      if behavior == :invoke && !File.exist?(config_file_name)
        template "graphql.yml", config_file_name
      end
    end
  end

  def download_schema
    say "      downloading GraphQL schema from #{endpoint_url}..."

    if options['authorization'].present?
      rake "graphql:schema:update SERVICE=#{file_name} AUTHORIZATION='#{options['authorization']}'"
    else
      rake "graphql:schema:update SERVICE=#{file_name}"
    end
  end

  private

  def file_name # :doc:
    @_file_name ||= super.underscore
  end

  def client_file_name
    if mountable_engine?
      "app/operations/#{namespaced_path}/#{file_name}.rb"
    else
      "app/operations/#{file_name}.rb"
    end
  end

  def query_dir_gitkeep
    if mountable_engine?
      "app/operations/#{namespaced_path}/#{file_name}/.gitkeep"
    else
      "app/operations/#{file_name}/.gitkeep"
    end
  end

  def config_file_name
    "config/graphql.yml"
  end
end
