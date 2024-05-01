require_relative 'helpers/test_helper'

require 'active_support/core_ext/module/attribute_accessors'

class CallbacksTest < ActiveSupport::TestCase
  Client = Class.new(Artemis::Client) do
    def self.name
      'Github'
    end

    mattr_accessor :before_callback, :after_callback
    self.before_callback = nil
    self.after_callback = nil

    before_execute do |document, operation_name, variables, context|
      self.before_callback = document, operation_name, variables, context
    end

    after_execute do |data, errors, extensions|
      self.after_callback = data, errors, extensions
    end
  end

  Spotify = Class.new(Artemis::Client) do
    def self.name
      'Spotify'
    end

    before_execute do
      raise "this callback should not get invoked"
    end

    after_execute do
      raise "this callback should not get invoked"
    end
  end

  test ".before_execute gets invoked before executing" do
    Client.repository(owner: "yuki24", name: "artemis", context: { user_id: 'yuki24' })

    document, operation_name, variables, context = Client.before_callback

    assert_equal Client::Repository.document, document
    assert_equal 'CallbacksTest__Client__Repository', operation_name
    assert_equal({ "name" => "artemis", "owner" => "yuki24" }, variables)
    assert_equal({ user_id: 'yuki24' }, context)
  end

  test ".after_execute gets invoked after executing" do
    Client.user

    data, errors, extensions = Client.after_callback

    assert_equal({ "test" => "data" }, data)
    assert_equal [], errors
    assert_equal({}, extensions)
  end
end
