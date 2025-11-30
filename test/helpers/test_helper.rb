$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

require "active_support"
require 'active_support/core_ext/kernel/reporting'
require 'active_support/deprecation'
require 'active_support/testing/autorun'

require 'minitest/pride'
require "rails/railtie"
require 'artemis'

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


# This assumes that all of thw following methods are property implemented:
#
#   * +Artemis::Client.query_paths+
#   * +Artemis::GraphQLEndpoint.register!+
#   * +Artemis::GraphQLEndpoint.lookup+
#   * +Artemis::GraphQLEndpoint#load_schema!+
#
# The only method that doesn't need test coverage is +Artemis::Client.query_paths+. The rest of the methods should be
# tested, but we don't have any test setup for that yet.
Artemis::Client.query_paths = [File.expand_path('test/fixtures/')]

Artemis::GraphQLEndpoint.suppress_warnings_on_schema_load = true
Artemis::GraphQLEndpoint.register!(:github, adapter: :test, url: '', schema_path: 'test/fixtures/github/schema.json')
Artemis::GraphQLEndpoint.lookup(:github).load_schema!

require_relative '../fixtures/github'

PROJECT_DIR = FileUtils.pwd

require_relative 'fake_server'
server_thread = start_server
Minitest.after_run { teardown_server(server_thread) }
