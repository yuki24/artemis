# frozen_string_literal: true

require 'delegate'

require 'curb'

module Artemis
  module Adapters
    class CurbAdapter < AbstractAdapter
      attr_reader :multi

      def initialize(uri, service_name: , timeout: , pool_size: )
        super

        @multi = Curl::Multi.new
        @multi.pipeline = Curl::CURLPIPE_MULTIPLEX if defined?(Curl::CURLPIPE_MULTIPLEX)
      end

      def execute(document:, operation_name: nil, variables: {}, context: {})
        easy = Curl::Easy.new(uri.to_s)

        body = {}
        body["query"] = document.to_query_string
        body["variables"] = variables if variables.any?
        body["operationName"] = operation_name if operation_name

        easy.multi       = multi
        easy.headers     = headers(context) || {}
        easy.post_body   = JSON.generate(body)

        if defined?(Curl::CURLPIPE_MULTIPLEX)
          # This ensures libcurl waits for the connection to reveal if it is
          # possible to pipeline/multiplex on before it continues.
          easy.setopt(Curl::CURLOPT_PIPEWAIT, 1)
          easy.version = Curl::HTTP_2_0
        end

        easy.http_post

        if easy.response_code == 200 || easy.response_code == 400
          JSON.parse(easy.body)
        else
          { "errors" => [{ "message" => "#{easy.response_code} #{easy.body}" }] }
        end
      end
    end
  end
end
