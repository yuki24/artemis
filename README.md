# Artemis [![Build Status](https://travis-ci.org/yuki24/artemis.svg?branch=master)](https://travis-ci.org/yuki24/artemis)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'artemis'
```

And then execute:

    $ bundle

### Generators

#### Endpoint installer

```sh
$ rails g graphql:install metaphysics https://metaphysics-production.artsy.net/
```

**This has not yet been implemented.**

#### Query file generator

```sh
$ rails g graphql:query Artist
```

**This has not yet been implemented.**

## Examples

```yml
# config/graphql.yml
development:
  metaphysics:
    url: https://metaphysics-production.artsy.net/
```

```ruby
# app/queries/metaphysics.rb
class Metaphysics < Artemis::Client
end
```

```graphql
# app/queries/metaphysics/artwork.graphql
query($id: String!) {
  artwork(id: $id) {
    title
  }
}

# app/queries/metaphysics/me.graphql
query {
  me {
    name
  }
}
```

```ruby
results = Metaphysics.artwork(id: "andy-warhol-john-wayne-1986-number-377-cowboys-and-indians")
results.data
# => {
#      "data": {
#        "artwork": {
#          "title": "John Wayne, 1986 (#377, Cowboys & Indians)"
#        }
#      }
#    }

results = Metaphysics.with_context(headers: { "X-ACCESS-TOKEN": "..." }).me
results.data
# => {
#      "data": {
#        "me": {
#          "name": "Yuki Nishijima"
#        }
#      }
#    }
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
