# frozen_string_literal: true

require 'erb'
require 'yaml'

require 'active_support/core_ext/module/attribute_accessors'
require 'active_support/core_ext/string/inflections'

require 'artemis/exceptions'

module Artemis
  # TODO: Write documentation for +TestHelper+
  module TestHelper
    mattr_accessor :__graphql_fixture_path__

    # Creates an object that stubs a GraphQL request for the given +service+. No mock response is registered until the
    # +to_return+ method.
    #
    #   # test/fixtures/graphql/metaphysics/artist.yml
    #   leonardo_da_vinci:
    #     data:
    #       artist:
    #         name: Leonardo da Vinci
    #         birthday: 1452/04/15
    #
    #   # In a test:
    #   stub_graphql(Metaphysics, :artist).to_return(:leonardo_da_vinci)
    #
    #   response = Metaphysics.artist(id: "leonardo-da-vinci")
    #
    #   response.data.artist.name     # => "Leonardo da Vinci"
    #   response.data.artist.birthday # => "1452/04/15"
    #
    # Test responses could also be parameterized by specifying the +arguments+ argument for the query name.
    #
    #   stub_graphql(Metaphysics, :artist, id: "pablo-picasso").to_return(:pablo_picasso)
    #   stub_graphql(Metaphysics, :artist, id: "leonardo-da-vinci").to_return(:leonardo_da_vinci)
    #
    #   pablo_picasso = Metaphysics.artist(id: "pablo-picasso")
    #   da_vinci      = Metaphysics.artist(id: "leonardo-da-vinci")
    #
    #   pablo_picasso.data.artist.name # => "Pablo Picasso"
    #   da_vinci.data.artist.name      # => "Leonardo da Vinci"
    #
    def stub_graphql(service, query_name, arguments =  :__unspecified__)
      StubbingDSL.new(service.to_s, query_name, graphql_fixture_files, arguments)
    end

    # Returns out-going GraphQL requests.
    #
    def graphql_requests
      Artemis::Adapters::TestAdapter.requests
    end

    private

    def graphql_responses #:nodoc:
      Artemis::Adapters::TestAdapter.responses
    end

    def graphql_fixture_path #:nodoc:
      __graphql_fixture_path__ || raise(Artemis::ConfigurationError, "GraphQL fixture path is unset")
    end

    def graphql_fixture_files #:nodoc:
      @graphql_fixture_sets ||= Dir["#{graphql_fixture_path}/{**,*}/*.{yml,json}"]
                                  .uniq
                                  .select {|file| ::File.file?(file) }
                                  .map    {|file| GraphQLFixture.new(File.basename(file, File.extname(file)), file, read_erb_yaml(file)) }
    end

    def read_erb_yaml(path) #:nodoc:
      YAML.load(ERB.new(File.read(path)).result, aliases: true)
    end

    class StubbingDSL #:nodoc:
      attr_reader :service_name, :query_name, :fixture_sets, :arguments

      def initialize(service_name, query_name, fixture_sets, arguments) #:nodoc:
        @service_name, @query_name, @fixture_sets, @arguments = service_name, query_name, fixture_sets, arguments
      end

      def get(fixture_key)
        fixture_set = find_fixture_set
        fixture     = fixture_set.data[fixture_key.to_s]

        if fixture.nil?
          raise Artemis::FixtureNotFound, "Fixture `#{fixture_key}' not found in #{fixture_set.path}"
        end

        fixture
      end

      def to_return(fixture_key) #:nodoc:
        fixture_set = find_fixture_set
        fixture     = fixture_set.data[fixture_key.to_s]

        if fixture.nil?
          raise Artemis::FixtureNotFound, "Fixture `#{fixture_key}' not found in #{fixture_set.path}"
        end

        Artemis::Adapters::TestAdapter.responses <<
          TestResponse.new(
            "#{service_name}__#{fixture_set.name.to_s.camelcase}",
            arguments.respond_to?(:deep_stringify_keys) ? arguments.deep_stringify_keys : arguments,
            fixture
          )
      end

      private

      def find_fixture_set
        fixture_set = fixture_sets
                        .detect { |fixture| %r{#{service_name.underscore}/#{query_name}\.(yml|json)\z} =~ fixture.path }
        fixture_set ||= fixture_sets.detect { |fixture| fixture.name == query_name.to_s }

        if fixture_set.nil?
          raise Artemis::FixtureNotFound, "Fixture file `#{query_name}.{yml,json}' not found"
        end

        fixture_set
      end
    end

    TestResponse      = Struct.new(:operation_name, :arguments, :data) #:nodoc:
    GraphQLFixture    = Struct.new(:name, :path, :data) #:nodoc

    private_constant :GraphQLFixture, :StubbingDSL, :TestResponse
  end
end
