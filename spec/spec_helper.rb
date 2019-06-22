require 'artemis'
require 'pry'
require 'pry-byebug' if RUBY_ENGINE == 'ruby'

# This assumes that all of thw following methods are property implemented:
#
#   * +Artemis::Client.query_paths+
#   * +Artemis::GraphQLEndpoint.register!+
#   * +Artemis::GraphQLEndpoint.lookup+
#   * +Artemis::GraphQLEndpoint#load_schema!+
#
# The only method that doesn't need test coverage is +Artemis::Client.query_paths+. The rest of the methods should be
# tested, but we don't have any test setup for that yet.
Artemis::Client.query_paths = [File.join(__dir__, 'fixtures')]
Artemis::GraphQLEndpoint.suppress_warnings_on_schema_load = true
Artemis::GraphQLEndpoint.register!(:metaphysics, adapter: :test, url: '', schema_path: 'spec/fixtures/metaphysics/schema.json')
Artemis::GraphQLEndpoint.lookup(:metaphysics).load_schema!

require 'fixtures/metaphysics'

PROJECT_DIR = FileUtils.pwd

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  # config.warnings = true
  config.order = :random

  if config.files_to_run.one?
    config.default_formatter = "doc"
  end

  # Print the 10 slowest examples and example groups at the
  # end of the spec run, to help surface which specs are running
  # particularly slow.
  # config.profile_examples = 10

  # Seed global randomization in this process using the `--seed` CLI option.
  # Setting this allows you to use `--seed` to deterministically reproduce
  # test failures related to randomization by passing the same `--seed` value
  # as the one that triggered the failure.
  # Kernel.srand config.seed
end
