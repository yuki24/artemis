require "artemis/version"
require "artemis/client"
require "artemis/railtie" if defined?(Rails)

module Artemis
  def self.config_for_graphql(app)
    if app.respond_to?(:config_for)
      app.config_for(:graphql)
    else
      config_for(:graphql, app: app)
    end
  end

  # backported from https://github.com/rails/rails/blob/b9ca94ca/railties/lib/rails/application.rb#L226
  # TODO: Remove once dropping Rails <= 4.1 support
  def self.config_for(name, app:, env: Rails.env)
    if name.is_a?(Pathname)
      yaml = name
    else
      yaml = Pathname.new("#{app.paths["config"].existent.first}/#{name}.yml")
    end

    if yaml.exist?
      require "erb"
      (YAML.load(ERB.new(yaml.read).result) || {})[env] || {}
    else
      raise "Could not load configuration. No such file - #{yaml}"
    end
  rescue Psych::SyntaxError => e
    raise "YAML syntax error occurred while parsing #{yaml}. " \
      "Please note that YAML must be consistently indented using spaces. Tabs are not allowed. " \
      "Error: #{e.message}"
  end
end
