$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

require "active_support"
require 'active_support/core_ext/kernel/reporting'
require 'active_support/deprecation'
require 'active_support/testing/autorun'

require 'minitest/pride'
require 'pry'
require 'pry-byebug' if RUBY_ENGINE == 'ruby'
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
  ActiveSupport::TestCase.test_order = :sorted
end

Artemis::GraphQLEndpoint.suppress_warnings_on_schema_load = true
Artemis::GraphQLEndpoint.register!(:metaphysics, adapter: :test, url: '', schema_path: 'spec/fixtures/metaphysics/schema.json')
Artemis::GraphQLEndpoint.lookup(:metaphysics).load_schema!
