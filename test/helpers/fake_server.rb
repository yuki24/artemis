require 'json'
require 'rack'
require 'webrick'
require 'net/http'

RACK_SERVER = begin
                require 'rackup/handler/webrick'
                Rackup::Handler::WEBrick
              rescue LoadError
                Rack::Handler::WEBrick
              end

FAKE_SERVER = ->(env) {
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
        headers: env.select {|key, val| key.match("^HTTP.*|^CONTENT.*|^AUTHORIZATION.*") }
                    .collect {|key, val| [key.gsub(/^HTTP_/, ''), val.downcase] }
                    .to_h,
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

def start_server
  server_thread = Thread.new do
    RACK_SERVER.run(FAKE_SERVER, Port: 8000, Logger: WEBrick::Log.new('/dev/null'), AccessLog: [])
  end

  loop do
    begin
      TCPSocket.open('localhost', 8000)
      break
    rescue Errno::ECONNREFUSED
      # no-op
    end
  end

  server_thread
end

def teardown_server(server_thread)
  RACK_SERVER.shutdown
  server_thread.terminate
end
