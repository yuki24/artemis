require_relative 'helpers/test_helper'

require 'artemis/adapters/abstract_adapter'

class AdaptersTest < ActiveSupport::TestCase
  Artemis::Adapters::AbstractAdapter.send(:attr_writer, :uri, :timeout)

  test "NetHttpAdapter behaves like an adapter" do
    adapter = Artemis::Adapters::NetHttpAdapter.new("http://localhost:8000", service_name: nil, timeout: 0.5, pool_size: 5)

    assert_adapter adapter, Net::ReadTimeout
  end

  # Using Net::HTTP::Persistent some times gets the CI build stuck, so avoiding it in CI for now."
  # unless ENV["CI"]
  #   test "NetHttpPersistentAdapter behaves like an adapter" do
  #     adapter = Artemis::Adapters::NetHttpPersistentAdapter.new("http://localhost:8000", service_name: nil, timeout: 0.5, pool_size: 5)
  #
  #     assert_adapter adapter, Net::ReadTimeout
  #   ensure
  #     # Make sure the connection is closed otherwise the webrick server wouldn't be able to shut down.
  #     adapter.instance_variable_get(:@raw_connection)&.shutdown
  #   end
  # end

  # if RUBY_ENGINE == 'ruby'
  #   test "CurbAdapter behaves like an adapter" do
  #     adapter = Artemis::Adapters::CurbAdapter.new("http://localhost:8000", service_name: nil, timeout: 2, pool_size: 5)
  #
  #     assert_adapter adapter, Curl::Err::TimeoutError
  #   end
  # end

  test 'MultiDomainAdapter makes an actual HTTP request' do
    adapter = Artemis::Adapters::MultiDomainAdapter.new('ignored', service_name: nil, timeout: 0.5, pool_size: 5, adapter_options: { adapter: :net_http })

    response = adapter.execute(document: GraphQL::Client::IntrospectionDocument, context: { url: "http://localhost:8000/test_multi_domain" })

    assert_equal "Endpoint switched.", response['data']['body']
    assert_equal [], response['errors']
    assert_equal({}, response['extensions'])
  end

  test 'MultiDomainAdapter can make a multiplex (the graphql feature, not HTTP/2) request' do
    adapter = Artemis::Adapters::MultiDomainAdapter.new('ignored', service_name: nil, timeout: 0.5, pool_size: 5, adapter_options: { adapter: :net_http })

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
        url: "http://localhost:8000/test_multi_domain"
      }
    )

    assert_equal "Endpoint switched.", response['data']['body']
    assert_equal [], response['errors']
    assert_equal({}, response['extensions'])
  end

  test 'MultiDomainAdapter can make a multiplex request with custom HTTP headers' do
    adapter = Artemis::Adapters::MultiDomainAdapter.new('ignored', service_name: nil, timeout: 0.5, pool_size: 5, adapter_options: { adapter: :net_http })

    response = adapter.multiplex(
      [
        {
          query: GraphQL::Client::IntrospectionDocument.to_query_string,
          operationName: 'IntrospectionQuery',
        },
      ],
      context: {
        headers: {
          Authorization: "Token token",
        },
        url: "http://localhost:8000/test_multi_domain"
      }
    )

    assert_equal "token token", response['data']['headers']['AUTHORIZATION']
  end

  test 'MultiDomainAdapter raises an error when adapter_options.adapter is set to :multi domain' do
    assert_raises(ArgumentError, "You can not use the :multi_domain adapter with the :multi_domain adapter.") do
      Artemis::Adapters::MultiDomainAdapter.new('ignored', service_name: nil, timeout: 0.5, pool_size: 5, adapter_options: { adapter: :multi_domain })
    end
  end

  test 'MultiDomainAdapter raises an error when context.url is not specified' do
    adapter = Artemis::Adapters::MultiDomainAdapter.new('ignored', service_name: nil, timeout: 0.5, pool_size: 5, adapter_options: { adapter: :net_http })
    message = 'The MultiDomain adapter requires a url on every request. Please specify a ' \
              'url with a context: Client.with_context(url: "https://awesomeshop.domain.conm")'

    assert_raises(ArgumentError, message) do
      adapter.execute(document: GraphQL::Client::IntrospectionDocument)
    end
  end

  test 'MultiDomainAdapter raises an error when it receives a server error' do
    adapter = Artemis::Adapters::MultiDomainAdapter.new('ignored', service_name: nil, timeout: 0.5, pool_size: 5, adapter_options: { adapter: :net_http })

    assert_raises(Artemis::GraphQLServerError, "Received server error status 500: Server error") do
      adapter.execute(document: GraphQL::Client::IntrospectionDocument, context: { url: "http://localhost:8000/500" })
    end
  end

  test 'MultiDomainAdapter allows for overriding timeout' do
    adapter = Artemis::Adapters::MultiDomainAdapter.new('ignored', service_name: nil, timeout: 0.5, pool_size: 5, adapter_options: { adapter: :net_http })

    assert_raises(Net::ReadTimeout) do
      adapter.execute(document: GraphQL::Client::IntrospectionDocument, context: { url: "http://localhost:8000/slow_server" })
    end
  end

  private

  def assert_adapter(adapter, timeout_error)
    assert_adapter_initialization adapter
    assert_adapter_execution adapter
    assert_adapter_server_error adapter
    assert_adapter_timeout adapter, timeout_error
    # assert_adapter_multiplex adapter
    assert_adapter_multiplex_server_error adapter
    assert_adapter_multiplex_timeout adapter, timeout_error
  end

  def assert_adapter_initialization(adapter)
    assert_raises(ArgumentError, "url is required (given `nil`)") do
      adapter.class.new(nil, service_name: nil, timeout: 2, pool_size: 5)
    end
  end

  def assert_adapter_execution(adapter)
    response = adapter.execute(
      document: GraphQL::Client::IntrospectionDocument,
      operation_name: 'IntrospectionQuery',
      variables: { id: 'yayoi-kusama' },
      context: { user_id: 1 }
    )

    assert_equal GraphQL::Client::IntrospectionDocument.to_query_string, response['data']['body']['query']
    assert_equal({ 'id' => 'yayoi-kusama' }, response['data']['body']['variables'])
    assert_equal 'IntrospectionQuery', response['data']['body']['operationName']
    assert_equal 'application/json', response['data']['headers']['CONTENT_TYPE']
    assert_equal 'application/json', response['data']['headers']['ACCEPT']
    assert_equal [], response['errors']
    assert_equal({}, response['extensions'])
  end

  def assert_adapter_server_error(adapter)
    adapter.uri = URI.parse("http://localhost:8000/500")

    assert_raises(Artemis::GraphQLServerError, "Received server error status 500: Server error") do
      adapter.execute(document: GraphQL::Client::IntrospectionDocument, operation_name: 'IntrospectionQuery')
    end
  end

  def assert_adapter_timeout(adapter, timeout_error)
    adapter.uri = URI.parse("http://localhost:8000/slow_server")

    assert_raises(timeout_error) do
      adapter.execute(document: GraphQL::Client::IntrospectionDocument, operation_name: 'IntrospectionQuery')
    end
  end

  def assert_adapter_multiplex(adapter)
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

    assert_equal GraphQL::Client::IntrospectionDocument.to_query_string, introspection_query['data']['body']['query']
    assert_equal({ 'id' => 'yayoi-kusama' }, introspection_query['data']['body']['variables'])
    assert_equal 'IntrospectionQuery', introspection_query['data']['body']['operationName']
    assert_equal 'application/json', introspection_query['data']['headers']['CONTENT_TYPE']
    assert_equal 'application/json', introspection_query['data']['headers']['ACCEPT']
    assert_equal [], introspection_query['errors']
    assert_equal({}, introspection_query['extensions'])
  end

  def assert_adapter_multiplex_server_error(adapter)
    adapter.uri = URI.parse("http://localhost:8000/500")

    assert_raises(Artemis::GraphQLServerError, "Received server error status 500: Server error") do
      adapter.multiplex([])
    end
  end

  def assert_adapter_multiplex_timeout(adapter, timeout_error)
    adapter.uri = URI.parse("http://localhost:8000/slow_server")

    assert_raises(timeout_error) do
      adapter.multiplex([])
    end
  end
end
