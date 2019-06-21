describe Artemis::Configuration do
  let(:class_a) do
    Class.new(Artemis::Client) do
      self.query_paths = [File.join(__dir__, 'fixtures')]
      self.default_context = { user: 'user' }

      before_execute do |_|
        puts "hello class a"
      end

      def self.name
        'Metaphysics'
      end
    end
  end

  let(:class_b) do
    Class.new(Artemis::Client) do
      self.query_paths = [File.join(__dir__, 'fixtures')]
      self.default_context = { user: 'admin' }

      before_execute do |_|
        puts "hello class b"
      end

      def self.name
        'Metaphysics'
      end
    end
  end

  it 'ensures no configuration is overwritten' do
    expect(class_a.default_context).not_to eq(class_b.default_context)
    expect(class_a.before_execute.count).to eq(2)
    expect(class_b.before_execute.count).to eq(2)
  end

  context 'when initializing the client' do
    let(:instance_a) { class_a.new }
    let(:instance_b) { class_b.new }

    it 'keeps configuration seperate' do
      expect(instance_a.config.default_context).not_to eq(instance_b.config.default_context)
    end
  end

end
