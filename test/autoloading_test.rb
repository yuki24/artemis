require 'test_helper'

class AutoLoadingTest < ActiveSupport::TestCase
  test ".load_constant loads the specified constant if there is a matching graphql file" do
    Github.send(:remove_const, :User) if Github.constants.include?(:User)

    Github.load_constant(:User)

    assert_equal 'constant', defined?(Github::User)
  end

  test ".load_constant does nothing and returns nil if there is no matching file" do
    assert_nil Github.load_constant(:DoesNotExist)
  end

  test ".preload! preloads all the graphQL files in the query paths" do
    %i(User UserRepositories Repository RepositoryFields)
      .select {|const_name| Github.constants.include?(const_name) }
      .each {|const_name| Github.send(:remove_const, const_name) }

    Github.preload!

    assert_equal 'constant', defined?(Github::User)
    assert_equal 'constant', defined?(Github::Repository)
  end

  test "dynamically loads the matching GraphQL query and sets it to a constant" do
    Github.send(:remove_const, :User) if Github.constants.include?(:User)

    query = Github::User

    assert_equal <<~GRAPHQL.strip, query.document.to_query_string
      query Github__User {
        user(login: "yuki24") {
          id
          name
        }
      }
    GRAPHQL
  end

  test "dynamically loads the matching GraphQL fragment and sets it to a constant" do
    Github.send(:remove_const, :RepositoryFields) if Github.constants.include?(:RepositoryFields)

    query = Github::RepositoryFields

    assert_equal <<~GRAPHQL.strip, query.document.to_query_string
      fragment Github__RepositoryFields on Repository {
        name
        nameWithOwner
        url
        updatedAt
        languages(first: 1) {
          nodes {
            name
            color
          }
        }
      }
    GRAPHQL
  end

  test "correctly loads the matching GraphQL query even when the top-level constant with the same name exists" do
    # In Ruby <= 2.4 top-level constants can be looked up through a namespace, which turned out to be a bad practice.
    # This has been removed in 2.5, but in earlier versions still suffer from this behaviour.
    Github.send(:remove_const, :User) if Github.constants.include?(:User)
    Object.send(:remove_const, :User) if Object.constants.include?(:User)

    begin
      Object.send(:const_set, :User, 1)

      Github.user
    ensure
      Object.send(:remove_const, :User)
    end

    query = Github::User

    assert_equal <<~GRAPHQL.strip, query.document.to_query_string
      query Github__User {
        user(login: "yuki24") {
          id
          name
        }
      }
    GRAPHQL
  end

  test "raises an exception when the path was resolved but the file does not exist" do
    begin
      Github.graphql_file_paths << "github/removed.graphql"

      assert_raises(Errno::ENOENT) { Github::Removed }
    ensure
      Github.graphql_file_paths.delete("github/removed.graphql")
    end
  end

  test "raises an NameError when there is no graphql file that matches the const name" do
    assert_raises(NameError) { Github::DoesNotExist }
  end

  test "defines the query method when the matching class method gets called for the first time" do
    skip
    Github.undef_method(:user) if Github.public_instance_methods.include?(:user)

    Github.user

    expect(Github.public_instance_methods).to include(:user)
  end

  test "raises an NameError when there is no graphql file that matches the class method name" do
    assert_raises(NameError) { Github.does_not_exist }
  end

  test "raises an NameError when the class method name matches a fragment name" do
    assert_raises(NameError) { Github.repository_fields_fragment }
  end

  test "responds to a class method that has a matching graphQL file" do
    assert_respond_to Github, :user
  end

  test "does not respond to class methods that do not have a matching graphQL file" do
    assert_not_respond_to Github, :does_not_exist
  end

  test "defines the query method when the matching instance method gets called for the first time" do
    skip
    Github.undef_method(:user) if Github.public_instance_methods.include?(:user)

    Github.new.user

    expect(Github.public_instance_methods).to include(:user)
  end

  test "raises an NameError when there is no graphql file that matches the instance method name" do
    assert_raises(NameError) { Github.new.does_not_exist }
  end

  test "raises an NameError when the instance method name matches a fragment name" do
    assert_raises(NameError) { Github.new.repository_fields_fragment }
  end

  test "responds to the method that has a matching graphQL file" do
    assert_respond_to Github.new, :user
  end

  test "does not respond to methods that do not have a matching graphQL file" do
    assert_not_respond_to Github.new, :does_not_exist
  end
end