describe "#{GraphQL::Client} Callbacks" do
  Client = Class.new(Artemis::Client) do
    def self.name
      'Metaphysics'
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

  describe ".before_execute" do
    it "gets invoked before executing" do
      Client.artist(id: 'yayoi-kusama', context: { user_id: 'yuki24' })

      document, operation_name, variables, context = Client.before_callback

      expect(document).to eq(Client::Artist.document)
      expect(operation_name).to eq('Client__Artist')
      expect(variables).to eq('id' => 'yayoi-kusama')
      expect(context).to eq(user_id: 'yuki24')
    end
  end

  describe ".before_execute" do
    it "gets invoked after executing" do
      Client.artwork

      data, errors, extensions = Client.after_callback

      expect(data).to eq({})
      expect(errors).to eq({})
      expect(extensions).to eq(nil)
    end
  end
end