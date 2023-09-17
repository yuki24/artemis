describe "#{GraphQL::Client} Autoloading" do
  describe ".load_constant" do
    it "loads the specified constant if there is a matching graphql file" do
      Github.send(:remove_const, :User) if Github.constants.include?(:User)

      Github.load_constant(:User)

      expect(defined?(Github::User)).to eq('constant')
    end

    it "does nothing and returns nil if there is no matching file" do
      expect(Github.load_constant(:DoesNotExist)).to be_nil
    end
  end

  describe ".preload!" do
    it "preloads all the graphQL files in the query paths" do
      %i(User UserRepositories Repository RepositoryFields)
        .select {|const_name| Github.constants.include?(const_name) }
        .each {|const_name| Github.send(:remove_const, const_name) }

      Github.preload!

      expect(defined?(Github::User)).to eq('constant')
      expect(defined?(Github::Repository)).to eq('constant')
    end
  end

  it "dynamically loads the matching GraphQL query and sets it to a constant" do
    Github.send(:remove_const, :User) if Github.constants.include?(:User)

    query = Github::User

    expect(query.document.to_query_string).to eq(<<~GRAPHQL.strip)
      query Github__User {
        user(login: "yuki24") {
          id
          name
        }
      }
    GRAPHQL
  end

  it "dynamically loads the matching GraphQL fragment and sets it to a constant" do
    Github.send(:remove_const, :RepositoryFields) if Github.constants.include?(:RepositoryFields)

    query = Github::RepositoryFields

    expect(query.document.to_query_string).to eq(<<~GRAPHQL.strip)
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

  it "correctly loads the matching GraphQL query even when the top-level constant with the same name exists" do
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

    expect(query.document.to_query_string).to eq(<<~GRAPHQL.strip)
      query Github__User {
        user(login: "yuki24") {
          id
          name
        }
      }
    GRAPHQL
  end

  it "raises an exception when the path was resolved but the file does not exist" do
    begin
      Github.graphql_file_paths << "github/removed.graphql"

      expect { Github::Removed }.to raise_error(Errno::ENOENT)
    ensure
      Github.graphql_file_paths.delete("github/removed.graphql")
    end
  end

  it "raises an NameError when there is no graphql file that matches the const name" do
    expect { Github::DoesNotExist }.to raise_error(NameError)
  end

  xit "defines the query method when the matching class method gets called for the first time" do
    Github.undef_method(:user) if Github.public_instance_methods.include?(:user)

    Github.user

    expect(Github.public_instance_methods).to include(:user)
  end

  it "raises an NameError when there is no graphql file that matches the class method name" do
    expect { Github.does_not_exist }.to raise_error(NameError)
  end

  it "raises an NameError when the class method name matches a fragment name" do
    expect { Github.repository_fields_fragment }.to raise_error(NameError)
  end

  it "responds to a class method that has a matching graphQL file" do
    expect(Github).to respond_to(:user)
  end

  it "does not respond to class methods that do not have a matching graphQL file" do
    expect(Github).not_to respond_to(:does_not_exist)
  end

  xit "defines the query method when the matching instance method gets called for the first time" do
    Github.undef_method(:user) if Github.public_instance_methods.include?(:user)

    Github.new.user

    expect(Github.public_instance_methods).to include(:user)
  end

  it "raises an NameError when there is no graphql file that matches the instance method name" do
    expect { Github.new.does_not_exist }.to raise_error(NameError)
  end

  it "raises an NameError when the instance method name matches a fragment name" do
    expect { Github.new.repository_fields_fragment }.to raise_error(NameError)
  end

  it "responds to the method that has a matching graphQL file" do
    expect(Github.new).to respond_to(:user)
  end

  it "does not respond to methods that do not have a matching graphQL file" do
    expect(Github.new).not_to respond_to(:does_not_exist)
  end
end