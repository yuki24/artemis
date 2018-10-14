require 'json'
require 'rack'

describe 'Adapters' do
  FakeServer = ->(env) {
    body = {
      data: {
        body: JSON.parse(env['rack.input'].read),
        headers: env.select {|key, val| key.start_with?('HTTP_') }
                   .collect {|key, val| [key.gsub(/^HTTP_/, ''), val.downcase] }
                   .to_h,
      },
      errors: [],
      extensions: {}
    }.to_json

    [200, {}, [body]]
  }

  before :all do
    @server_thread = Thread.new do
      Rack::Handler::WEBrick.run(FakeServer, Port: 8000, Logger: WEBrick::Log.new('/dev/null'), AccessLog: [])
    end

    loop do
      begin
        TCPSocket.open('localhost', 8000)
        break
      rescue Errno::ECONNREFUSED
        # no-op
      end
    end
  end

  after :all do
    Rack::Handler::WEBrick.shutdown
    @server_thread.terminate
  end

  shared_examples 'an adapter' do
    describe '#execute' do
      it 'makes an actual HTTP request' do
        response = adapter.execute(
          document: GraphQL::Client::IntrospectionDocument,
          operation_name: 'IntrospectionQuery',
          variables: { id: 'yayoi-kusama' },
          context: { user_id: 1 }
        )

        expect(response['data']['body']['query']).to eq(GraphQL::Client::IntrospectionDocument.to_query_string)
        expect(response['data']['body']['variables']).to eq('id' => 'yayoi-kusama')
        expect(response['data']['body']['operationName']).to eq('IntrospectionQuery')
        expect(response['errors']).to eq([])
        expect(response['extensions']).to eq({})
      end
    end
  end

  describe Artemis::Adapters::NetHttpAdapter do
    let(:adapter) { Artemis::Adapters::NetHttpAdapter.new('http://localhost:8000', service_name: nil, timeout: 5, pool_size: 5) }

    it_behaves_like 'an adapter'
  end

  describe Artemis::Adapters::NetHttpPersistentAdapter do
    let(:adapter) { Artemis::Adapters::NetHttpPersistentAdapter.new('http://localhost:8000', service_name: nil, timeout: 5, pool_size: 5) }

    it_behaves_like 'an adapter'
  end

  describe Artemis::Adapters::CurbAdapter do
    let(:adapter) { Artemis::Adapters::CurbAdapter.new('http://localhost:8000', service_name: nil, timeout: 5, pool_size: 5) }

    it_behaves_like 'an adapter'
  end
end