require 'json'
require 'rack'
require 'webrick'

describe 'Adapters' do
  FakeServer = ->(env) {
    case env['PATH_INFO']
    when '/slow_server'
      sleep 2.1

      [200, {}, ['{}']]
    when '/500'
      [500, {}, ['Server error']]
    when '/test_multi_domain'
      body = {
        data: {
          body: "Endpoint switched.",
        },
        errors: [],
        extensions: {}
      }.to_json

      [200, {}, [body]]
    else
      request_body = JSON.parse(env['rack.input'].read)

      response_body = if request_body['_json']
                        request_body['_json'].map do |query|
                          {
                            data: {
                              body: query,
                              headers: env.select {|key, val| key.match("^HTTP.*|^CONTENT.*|^AUTHORIZATION.*") }
                                          .collect {|key, val| [key.gsub(/^HTTP_/, ''), val.downcase] }
                                          .to_h,
                            },
                            errors: [],
                            extensions: {}
                          }
                        end.to_json
                      else
                        {
                          data: {
                            body: request_body,
                            headers: env.select {|key, val| key.match("^HTTP.*|^CONTENT.*|^AUTHORIZATION.*") }
                                        .collect {|key, val| [key.gsub(/^HTTP_/, ''), val.downcase] }
                                        .to_h,
                          },
                          errors: [],
                          extensions: {}
                        }.to_json
                      end

      [200, {}, [response_body]]
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
        expect(response['data']['headers']['CONTENT_TYPE']).to eq('application/json')
        expect(response['data']['headers']['ACCEPT']).to eq('application/json')
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

    describe '#multiplex' do
      it 'makes an HTTP request with multiple queries' do
        response = adapter.multiplex(
          [
            {
              query: GraphQL::Client::IntrospectionDocument.to_query_string,
              operationName: 'IntrospectionQuery',
              variables: {
                id: 'yayoi-kusama'
              },
            },
          ],
          context: {
            user_id: 1
          }
        )

        introspection_query = response[0]

        expect(introspection_query['data']['body']['query']).to eq(GraphQL::Client::IntrospectionDocument.to_query_string)
        expect(introspection_query['data']['body']['variables']).to eq('id' => 'yayoi-kusama')
        expect(introspection_query['data']['body']['operationName']).to eq('IntrospectionQuery')
        expect(introspection_query['data']['headers']['CONTENT_TYPE']).to eq('application/json')
        expect(introspection_query['data']['headers']['ACCEPT']).to eq('application/json')
        expect(introspection_query['errors']).to eq([])
        expect(introspection_query['extensions']).to eq({})
      end

      it 'raises an error when it receives a server error' do
        adapter.uri = URI.parse('http://localhost:8000/500')

        expect do
          adapter.multiplex([])
        end.to raise_error(Artemis::GraphQLServerError, "Received server error status 500: Server error")
      end

      it 'allows for overriding timeout' do
        adapter.uri = URI.parse('http://localhost:8000/slow_server')

        expect do
          adapter.multiplex([])
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
    let(:timeout_error) { Net::ReadTimeout }

    it_behaves_like 'an adapter'
  end

  describe Artemis::Adapters::MultiDomainAdapter do
    let(:adapter) { Artemis::Adapters::MultiDomainAdapter.new('ignored', service_name: nil, timeout: 0.5, pool_size: 5, adapter_options: { adapter: :net_http }) }

    it 'makes an actual HTTP request' do
      response = adapter.execute(document: GraphQL::Client::IntrospectionDocument, context: { url: 'http://localhost:8000/test_multi_domain' })

      expect(response['data']['body']).to eq("Endpoint switched.")
      expect(response['errors']).to eq([])
      expect(response['extensions']).to eq({})
    end

    it 'raises an error when adapter_options.adapter is set to :multi domain' do
      expect do
        Artemis::Adapters::MultiDomainAdapter.new('ignored', service_name: nil, timeout: 0.5, pool_size: 5, adapter_options: { adapter: :multi_domain })
      end.to raise_error(ArgumentError, 'You can not use the :multi_domain adapter with the :multi_domain adapter.')
    end

    it 'raises an error when context.url is not specified' do
      expect do
        adapter.execute(document: GraphQL::Client::IntrospectionDocument)
      end.to raise_error(ArgumentError, 'The MultiDomain adapter requires a url on every request. Please specify a ' \
                                        'url with a context: Client.with_context(url: "https://awesomeshop.domain.conm")')
    end

    it 'raises an error when it receives a server error' do
      expect do
        adapter.execute(document: GraphQL::Client::IntrospectionDocument, context: { url: 'http://localhost:8000/500' })
      end.to raise_error(Artemis::GraphQLServerError, "Received server error status 500: Server error")
    end

    it 'allows for overriding timeout' do
      expect do
        adapter.execute(document: GraphQL::Client::IntrospectionDocument, context: { url: 'http://localhost:8000/slow_server' })
      end.to raise_error(Net::ReadTimeout)
    end
  end

  if RUBY_ENGINE == 'ruby'
    describe Artemis::Adapters::CurbAdapter do
      let(:adapter) { Artemis::Adapters::CurbAdapter.new('http://localhost:8000', service_name: nil, timeout: 2, pool_size: 5) }
      let(:timeout_error) { Curl::Err::TimeoutError }

      it_behaves_like 'an adapter'
    end
  end
end
