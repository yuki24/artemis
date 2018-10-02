describe "#{GraphQL::Client} Autoloading" do
  describe ".load_constant" do
    it "loads the specified constant if there is a matching graphql file" do
      Metaphysics.send(:remove_const, :Artist) if Metaphysics.constants.include?(:Artist)

      Metaphysics.load_constant(:Artist)

      expect(defined?(Metaphysics::Artist)).to eq('constant')
    end

    it "does nothing and returns nil if there is no matching file" do
      expect(Metaphysics.load_constant(:DoesNotExist)).to be_nil
    end
  end

  describe ".preload!" do
    it "preloads all the graphQL files in the query paths" do
      Metaphysics.send(:remove_const, :Artist)  if Metaphysics.constants.include?(:Artist)
      Metaphysics.send(:remove_const, :Artwork) if Metaphysics.constants.include?(:Artwork)

      Metaphysics.preload!

      expect(defined?(Metaphysics::Artist)).to eq('constant')
      expect(defined?(Metaphysics::Artwork)).to eq('constant')
    end
  end

  it "dynamically loads the matching GraphQL query and sets it to a constant" do
    Metaphysics.send(:remove_const, :Artist) if Metaphysics.constants.include?(:Artist)

    query = Metaphysics::Artist

    expect(query.document.to_query_string).to eq(<<~GRAPHQL.strip)
      query Metaphysics__Artist($id: String!) {
        artist(id: $id) {
          name
          bio
          birthday
        }
      }
    GRAPHQL
  end

  it "raises an exception when the path was resolved but the file does not exist" do
    begin
      Metaphysics.graphql_file_paths << "metaphysics/removed.graphql"

      expect { Metaphysics::Removed }.to raise_error(Errno::ENOENT)
    ensure
      Metaphysics.graphql_file_paths.delete("metaphysics/removed.graphql")
    end
  end

  it "raises an NameError when there is no graphql file that matches the const name" do
    expect { Metaphysics::DoesNotExist }.to raise_error(NameError)
  end

  xit "defines the query method when the matching class method gets called for the first time" do
    Metaphysics.undef_method(:artwork) if Metaphysics.public_instance_methods.include?(:artwork)

    Metaphysics.artwork

    expect(Metaphysics.public_instance_methods).to include(:artwork)
  end

  it "raises an NameError when there is no graphql file that matches the class method name" do
    expect { Metaphysics.does_not_exist }.to raise_error(NameError)
  end

  it "responds to a class method that has a matching graphQL file" do
    expect(Metaphysics).to respond_to(:artwork)
  end

  it "does not respond to class methods that do not have a matching graphQL file" do
    expect(Metaphysics).not_to respond_to(:does_not_exist)
  end

  xit "defines the query method when the matching instance method gets called for the first time" do
    Metaphysics.undef_method(:artwork) if Metaphysics.public_instance_methods.include?(:artwork)

    Metaphysics.new.artwork

    expect(Metaphysics.public_instance_methods).to include(:artwork)
  end

  it "raises an NameError when there is no graphql file that matches the instance method name" do
    expect { Metaphysics.new.does_not_exist }.to raise_error(NameError)
  end

  it "responds to the method that has a matching graphQL file" do
    expect(Metaphysics.new).to respond_to(:artwork)
  end

  it "does not respond to methods that do not have a matching graphQL file" do
    expect(Metaphysics.new).not_to respond_to(:does_not_exist)
  end
end