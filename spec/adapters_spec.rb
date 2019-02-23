require 'json'
require 'rack'

describe 'Adapters' do
  FakeServer = ->(env) {
    case env['PATH_INFO']
    when '/slow_server'
      sleep 1.1

      [200, {}, ['{}']]
    when '/500'
      [500, {}, ['Server error']]
    else
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
    end
  }

  before :all do
    Artemis::Adapters::AbstractAdapter.send(:attr_writer, :uri, :timeout)

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
    describe '#initialize' do
      it 'requires an url' do
        expect do
          adapter.class.new(nil, service_name: nil, timeout: 2, pool_size: 5)
        end.to raise_error(ArgumentError, "url is required (given `nil')")
      end
    end

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

      it 'raises an error when it receives a server error' do
        adapter.uri = URI.parse('http://localhost:8000/500')

        expect do
          adapter.execute(document: GraphQL::Client::IntrospectionDocument, operation_name: 'IntrospectionQuery')
        end.to raise_error(Artemis::GraphQLServerError, "Received server error status 500: Server error")
      end

      it 'allows for overriding timeout' do
        adapter.uri = URI.parse('http://localhost:8000/slow_server')

        expect do
          adapter.execute(document: GraphQL::Client::IntrospectionDocument, operation_name: 'IntrospectionQuery')
        end.to raise_error(timeout_error)
      end
    end
  end

  describe Artemis::Adapters::NetHttpAdapter do
    let(:adapter) { Artemis::Adapters::NetHttpAdapter.new('http://localhost:8000', service_name: nil, timeout: 0.5, pool_size: 5) }
    let(:timeout_error) { Net::ReadTimeout }

    it_behaves_like 'an adapter'
  end

  describe Artemis::Adapters::NetHttpPersistentAdapter do
    let(:adapter) { Artemis::Adapters::NetHttpPersistentAdapter.new('http://localhost:8000', service_name: nil, timeout: 0.5, pool_size: 5) }
    let(:timeout_error) { Net::HTTP::Persistent::Error }

    it_behaves_like 'an adapter'
  end

  describe Artemis::Adapters::CurbAdapter do
    let(:adapter) { Artemis::Adapters::CurbAdapter.new('http://localhost:8000', service_name: nil, timeout: 2, pool_size: 5) }
    let(:timeout_error) { Curl::Err::TimeoutError }

    it_behaves_like 'an adapter'
  end
end