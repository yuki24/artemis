$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

require "active_support"
require 'active_support/core_ext/kernel/reporting'
require 'active_support/deprecation'
require 'active_support/testing/autorun'

require 'minitest/pride'
require 'pry'
require 'pry-byebug' if RUBY_ENGINE == 'ruby'
require "rails/railtie"

begin
  require 'active_support/testing/method_call_assertions'
  ActiveSupport::TestCase.include ActiveSupport::Testing::MethodCallAssertions
rescue LoadError
  # Rails 4.2 doesn't come with ActiveSupport::Testing::MethodCallAssertions
  require 'backport/method_call_assertions'
  ActiveSupport::TestCase.include MethodCallAssertions

  # FIXME: we have tests that depend on run order, we should fix that and
  # remove this method call.
  require 'active_support/test_case'
  ActiveSupport::TestCase.test_order = :sorted if ActiveSupport::TestCase.respond_to?(:test_order=)
end

module Paths
  def app_template_path
    File.join Dir.tmpdir, "app_template"
  end

  def tmp_path(*args)
    @tmp_path ||= File.realpath(Dir.mktmpdir)
    File.join(@tmp_path, *args)
  end

  def app_path(*args)
    tmp_path(*%w[app] + args)
  end
end

module Generation
  extend Paths
  include Paths

  # Build an application by invoking the generator and going through the whole stack.
  def build_app(options = {})
    @prev_rails_env = ENV["RAILS_ENV"]
    ENV["RAILS_ENV"] = "development"
    ENV["SECRET_KEY_BASE"] ||= SecureRandom.hex(16)

    FileUtils.rm_rf(app_path)
    FileUtils.cp_r(app_template_path, app_path)

    # Delete the initializers unless requested
    unless options[:initializers]
      Dir["#{app_path}/config/initializers/**/*.rb"].each do |initializer|
        File.delete(initializer)
      end
    end

    add_to_config <<-RUBY
      config.eager_load = false
      config.session_store :cookie_store, key: "_myapp_session"
      config.active_support.deprecation = :log
      config.active_support.test_order = :random
      config.action_controller.allow_forgery_protection = false
      config.log_level = :info
    RUBY
  end

  def teardown_app
    ENV["RAILS_ENV"] = @prev_rails_env if @prev_rails_env
    FileUtils.rm_rf(tmp_path)
  end

  def add_to_config(str)
    environment = File.read("#{app_path}/config/application.rb")
    if environment =~ /(\n\s*end\s*end\s*)\z/
      File.open("#{app_path}/config/application.rb", "w") do |f|
        f.puts $` + "\n#{str}\n" + $1
      end
    end
  end

  def self.initialize_app
    FileUtils.rm_rf(app_template_path)
    FileUtils.mkdir(app_template_path)

    `rails new #{app_template_path} --skip-gemfile --skip-action-cable --skip-active-storage --skip-active-record --skip-sprockets --skip-javascript --skip-listen --no-rc`

    File.open("#{app_template_path}/config/boot.rb", "w")
  end
end

Generation.initialize_app

require 'artemis'

Artemis::GraphQLEndpoint.suppress_warnings_on_schema_load = true

require 'rack'
require 'json'

FakeServer = ->(env) {
  body = {
    data: {
      body: JSON.parse(env['rack.input'].read),
      headers: env.select {|key, val| key.start_with?('HTTP_') }
                 .collect {|key, val| [key.gsub(/^HTTP_/, ''), val.downcase] }
                 .to_h,
    },
    errors: [],
    extensions: { }
  }.to_json

  [200, {}, [body]]
}

SERVER_THREAD = Thread.new do
  Rack::Handler::WEBrick.run(FakeServer, Port: 8000, Logger: WEBrick::Log.new('/dev/null'), AccessLog: [])
end

loop do
  begin
    TCPSocket.open('localhost', 8000)
    break
  rescue Errno::ECONNREFUSED
    # no-op
  end
end
