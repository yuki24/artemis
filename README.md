# Artemis [![Build Status](https://travis-ci.org/yuki24/artemis.svg?branch=master)](https://travis-ci.org/yuki24/artemis)

Artemis is a GraphQL client that is designed to fit well on Rails.

 * **Convention over Configuration**: You'll never have to make trivial decisions or spend time on boring setup. Start
  making a GraphQL request in literally 30s.
 * **Performant by default**: You can't do wrong when it comes to performance. All GraphQL files are pre-loaded only
  once in production and it'll never affect runtime performance. Comes with options that enable persistent connections
   and even HTTP/2, the next-gen high-performance protocol.
 * **First-class support for testing**: Testing and stubbing GraphQL requests couldn't be simpler. No need to add
  external dependencies to test well.

<img width="24" height="24" src="https://avatars1.githubusercontent.com/u/541332?s=48&amp;v=4"> Battle-tested at [Artsy](https://www.artsy.net)

![graphql-client vs Artemis](https://raw.githubusercontent.com/yuki24/artemis/master/banner.png "graphql-client vs Artemis")

## Getting started

Add this line to your application's Gemfile:

```ruby
gem 'artemis'
```

Once you run `bundle install` on your Rails app, run the install command:


```sh
$ rails g artemis:install artsy https://metaphysics-production.artsy.net/

# or if you need to specify the `--authorization` header:
$ rails g artemis:install github https://api.github.com/graphql --authorization 'token ...'
```

### Generating your first query

Artemis comes with a query generator. For exmaple, you could use the query generator to generate a query stub for `artist`:

```sh
$ rails g artemis:query artist
```

Then this will generate:

```graphql
# app/operations/artist.graphql
query($id: String!) {
  artist(id: $id) {
    # Add fields here...
  }
}
```

Then you could the class method that has the matching name `artist`:

```ruby
Artsy.artist(id: "pablo-picasso")
# => makes a GraphQL query that's in app/operations/artist.graphql
```

You can also specify a file name:

```sh
$ rails g artemis:query artist artist_details_on_artwork
# => generates app/operations/artist_details_on_artwork.graphql
```

Then you can make a query in `artist_details_on_artwork.graphql` with:

```ruby
Artsy.artist_details_on_artwork(id: "pablo-picasso")
```

## The convention

Artemis assumes that the files related to GraphQL are organized in a certain way. For example, a service that talks to Artsy's GraphQL API could have the following structure:

```
├──app/operations
│   ├── artsy
│   │   ├── _artist_fragment.graphql
│   │   ├── artwork.graphql
│   │   ├── artist.graphql
│   │   └── artists.graphql
│   └── artsy.rb
├──config/graphql.yml
├──test/fixtures/graphql
│   └── artsy
│       ├── artwork.yml
│       ├── artist.yml
│       └── artists.yml
└──vendor/graphql/schema/artsy.json
```

## Callbacks

Youcan use the `before_execute` callback to intercept outgoing requests and the `after_execute` callback to observe the
response. A common operation that's done in the `before_execute` hook is assigning a token to the header:

```ruby
class Artsy < Artemis::Client
  before_execute do |document, operation_name, variables, context|
    context[:headers] = {
      Authorization: "token ..."
    }
  end
end
```

Here the `:headers` key is a special context type. The hash object assigned to the `context[:headers]` will be sent as
the HTTP headers of the request.

Another common thing when receiving a response is to check if there's any error in the response and throw and error
accordingly:

```ruby
class Artsy < Artemis::Client
  after_execute do |data, errors, extensions|
    raise "GraphQL error: #{errors.to_json}" if errors.present?
  end
end
```

## Configuration

You can configure the GraphQL client using the following options. Those configurations are found in the
`config/graphql.yml`.

| Name          | Required? | Default     | Description |
| ------------- | --------- | ------------| ----------- |
| `adapter`     | No        | `:net_http` | The underlying client library that actually makes an HTTP request. See Adapters for available options.
| `pool_size`   | No        | 25          | The number of keep-alive connections. The `:net_http` adapter will ignore this option.
| `schema_path` | No        | See above   | The path to the GrapQL schema. Setting an empty value to this will force the client to download the schema upon the first request.
| `timeout`     | No        | 10          | HTTP timeout set for the adapter in seconds. This will be set to both `read_timeout` and `write_timeout` and there is no way to configure them with a different value as of writing (PRs welcome!)
| `url`         | Yes       | N/A         | The URL for the GraphQL endpoint.

### Adapters

There are four adapter options available. Choose the adapter that best fits on your use case.

| Adapter                | Protocol                 | Keep-alive  | Performance | Dependencies |
| ---------------------- | ------------------------ | ----------- | ----------- | ------------ |
| `:curb`                | HTTP/1.1, **HTTP/2**     | **Yes**     | **Fastest** | [`curb 0.9.6+`][curb]<br>[`libcurl 7.64.0+`][curl]<br>[`nghttp2 1.0.0+`][nghttp]
| `:net_http` (default)  | HTTP/1.1 only            | No          | Slow        | **None**
| `:net_http_persistent` | HTTP/1.1 only            | **Yes**     | **Fast**    | [`net-http-persistent 3.0.0+`][nhp]
| `:test`                | N/A (See Testing)

### Third-party adapters

This is a comminuty-maintained adapter. Want to add yours? Send us a pull request!

| Adapter                | Description |
| ---------------------- | ------------|
| [`:net_http_hmac`](https://github.com/JanStevens/artemis-api-auth/tree/master)      | provides a new Adapter for the Artemis GraphQL ruby client to support HMAC Authentication using [ApiAuth](https://github.com/mgomes/api_auth). |

### Writing your own adapter

When the built-in adapters do not satisfy your needs, you may want to implement your own adapter. You could do so by following the steps below. Let's implement the [`:net_http_hmac`](https://github.com/JanStevens/artemis-api-auth/tree/master) adapter as an example.

 1. Define `NetHttpHmacAdapter` under the `Artemis::Adapters` namespace and implement [the `#execute` method](https://github.com/github/graphql-client/blob/master/guides/remote-queries.md):

    ```ruby
    # lib/artemis/adapters/net_http_hmac_adapter.rb
    module Artemis::Adapters
      class NetHttpHmacAdapter
        def execute(document:, operation_name: nil, variables: {}, context: {})
          # Makes an HTTP request for GraphQL query.
        end
      end
    end
    ```

 2. Load the adapter in `config/initializers/artemis.rb` (or any place that gets loaded before Rails runs initializers):

    ```ruby
    require 'artemis/adapters/net_http_hmac_adapter'
    ```

 3. Specify the adapter name in `config/graphql.yml`:

    ```yml
    default: &default
      adapter: :net_http_hmac
    ```

## Rake tasks

Artemis also adds a useful `rake graphql:schema:update` rake task that downloads the GraphQL schema using the
`Introspection` query.

### `graphql:schema:update`

Downloads and saves the GraphQL schema.

| Option Name        | Description |
| ------------------ | ------------|
| `SERVICE`          | Service name the schema is downloaded from.| 
| `AUTHORIZATION`    | HTTP `Authorization` header value used to download the schema with.|


#### Examples

```
$ rake graphql:schema:update
# => downloads schema from the service. fails if there are multiple services in config/graphql.yml.

$ rake graphql:schema:update SERVICE=github AUTHORIZATION="token ..."
# => downloads schema from the `github` service using the HTTP header "AUTHORIZATION: token ..."
```

## Testing

Given that you have `app/operations/artsy/artist.graphql` and fixture file for the `artist.yml`:

```yml
# test/fixtures/graphql/artist.yml:
leonardo_da_vinci:
  data:
    artist:
      name: Leonardo da Vinci
      birthday: 1452/04/15

yayoi_kusama:
  data:
    artist:
      name: Yayoi Kusama
      birthday: 1929/03/22
```

Then you can stub the request with the `stub_graphql` DSL:

```ruby
stub_graphql(Artsy, :artist, id: "yayoi-kusama").to_return(:yayoi_kusama)
stub_graphql(Artsy, :artist, id: "leonardo-da-vinci").to_return(:leonardo_da_vinci)

yayoi_kusama = Artsy.artist(id: "yayoi-kusama")
yayoi_kusama.data.artist.name     # => "Yayoi Kusama"
yayoi_kusama.data.artist.birthday # => "1452/04/15"

da_vinci = Artsy.artist(id: "leonardo-da-vinci")
da_vinci.data.artist.name     # => "Leonardo da Vinci"
da_vinci.data.artist.birthday # => "1452/04/15"
```

You can also use JSON instead of YAML. See [example fixtures](https://github.com/yuki24/artemis/tree/master/spec/fixtures/responses)
and [test cases](https://github.com/yuki24/artemis/blob/master/spec/test_helper_spec.rb#L16-L51).

### MiniTest

Setting up the test helper with Artemis is very easy and simple. Just add the following code to the
`test/test_helper.rb` in your app:

```ruby
# spec/test_helper.rb
require 'artemis/test_helper'

class ActiveSupport::TestCase
  setup do
    graphql_requests.clear
    graphql_responses.clear
  end
end
```

### RSpec

Artemis also comes with a script that wires up helper methods on Rspec. Because it is more common to use the `spec/`
directory to organize spec files in RSpec, the `config.artemis.fixture_path` config needs to point to
`spec/fixtures/graphql`. Other than that, it is very straightforward to set it up:

```ruby
# config/application.rb
config.artemis.fixture_path = 'spec/fixtures/graphql'
```

```ruby
# Add this to your spec/rails_helper.rb or spec_helper.rb if you don't have rails_helper.rb
require 'artemis/rspec'
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/yuki24/artemis. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Artemis project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/artemis/blob/master/CODE_OF_CONDUCT.md).

[curb]: https://rubygems.org/gems/curb
[curl]: https://curl.haxx.se/docs/http2.html
[nghttp]: https://nghttp2.org/
[nhp]: https://rubygems.org/gems/net-http-persistent
