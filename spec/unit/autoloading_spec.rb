describe "#{GraphQL::Client} Autoloading" do
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

  it "raises an exception when the path was resolved but the file does not exist"

  it "raises an NameError when there is no graphql file that matches the const name" do
    expect { Metaphysics::DoesNotExist }.to raise_error(NameError)
  end

  it "defines the query method when the matching class method gets called for the first time" do
    Metaphysics.undef_method(:artwork) if Metaphysics.public_methods.include?(:artwork)

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

  it "defines the query method when the matching instance method gets called for the first time" do
    Metaphysics.undef_method(:artwork) if Metaphysics.public_methods.include?(:artwork)

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