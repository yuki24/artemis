## v0.5.3

_<sup>(unreleased)</sup>_

#### Fixes

 * Generate fixture YAML files on `rails g artemis:query queryName` (#78)
 * Address warnings from Ruby 2.7 (408adcb3)
 * Avoid crashing when config/graphql.yml does not exist (@dlackty, #76)

## [v0.5.2](https://github.com/yuki24/artemis/tree/v0.5.2)

_<sup>released at 2019-07-26 03:21:43 UTC</sup>_

#### Fixes

- Fixes an issue where fixtures can not be looked up properly when the client has two or more words in its name ([@JanStevens](https://github.com/JanStevens), issue: [#72](https://github.com/yuki24/artemis/issues/72), PR: [#73](https://github.com/yuki24/artemis/pull/73))

## [v0.5.1](https://github.com/yuki24/artemis/tree/v0.5.1)

_<sup>released at 2019-07-01 14:25:35 UTC</sup>_

#### Fixes

- Fixes an issue where callbacks are shared across all clients ([@JanStevens](https://github.com/JanStevens), issue: [#69](https://github.com/yuki24/artemis/issues/69), PR: [#70](https://github.com/yuki24/artemis/pull/70))
- Fixes an issue where fixtures with the same name cause a conflict ([@JanStevens](https://github.com/JanStevens), Issue: [#68](https://github.com/yuki24/artemis/issues/68), commit: [<tt>e1f57f4</tt>](https://github.com/yuki24/artemis/commit/e1f57f49ebb032553d7a6f70e48422fc9825c119))

## [v0.5.0](https://github.com/yuki24/artemis/tree/v0.5.0)

_<sup>released at 2019-06-02 22:01:57 UTC</sup>_

#### Features

- Add support for Rails 6.0, 4.1, and 4.0
- [<tt>6701b54</tt>](https://github.com/yuki24/artemis/commit/6701b546a143c22109c7ab30018acf96d67067d1), [#62](https://github.com/yuki24/artemis/issues/62): Allow to dynamically call the operation ([@JanStevens](https://github.com/JanStevens))

#### Fixes

- [#67](https://github.com/yuki24/artemis/pull/67): Fix the wrong test version constraints in `Appraisals` ([@daemonsy](https://github.com/daemonsy))
- [#60](https://github.com/yuki24/artemis/pull/60): Fix an issue where not all adapters send required HTTP headers

## [v0.4.0](https://github.com/yuki24/artemis/tree/v0.4.0)

_<sup>released at 2019-01-30 03:42:14 UTC</sup>_

#### Features

- [<tt>48d052e</tt>](https://github.com/yuki24/artemis/commit/48d052e9819703f1cefa95fbdb431bd03928f4ed): Add an easy way to set up Rspec integration
- [<tt>0f7cd12</tt>](https://github.com/yuki24/artemis/commit/0f7cd120594a0dd2a4af2b2e5cf990891dd8de16): Make Artemis' Railtie configurable
- [<tt>6bd15e2</tt>](https://github.com/yuki24/artemis/commit/6bd15e20779e5a6f898e1aacf8237c94c8c46aba): Add the ability to use ERB in test fixtures
- [#49](https://github.com/yuki24/artemis/pull/49): Expose the TestAdapter as a public API

#### Bug fixes

- [<tt>b7ad4a4</tt>](https://github.com/yuki24/artemis/commit/b7ad4a481a43cadd9193076c0e44938e05e6d44b): Require `graphl >= 1.8` to fix a bug in the generator
- [#48](https://github.com/yuki24/artemis/pull/48): Do not transform keys of query variables ([@erikdstock](https://github.com/erikdstock))
- [#47](https://github.com/yuki24/artemis/pull/47): Fixes an issue where errors thrown from `config/graphql.yml` get swallowed

## [v0.2.0: New generators and small improvements](https://github.com/yuki24/artemis/tree/v0.2.0)

_<sup>released at 2018-10-30 02:09:59 UTC</sup>_

#### Features

- [#43](https://github.com/yuki24/artemis/pull/43): Keep persistent connections open for 30 minutes
- [#42](https://github.com/yuki24/artemis/pull/42): Allow for setting up the test adapter without `url`
- [#41](https://github.com/yuki24/artemis/pull/41): Add a mutation generator
- [#40](https://github.com/yuki24/artemis/pull/40): Add a query generator
- [#39](https://github.com/yuki24/artemis/pull/39): Installer now adds a new service if `config/graphql.yml` is present

## [v0.1.0: First release!](https://github.com/yuki24/artemis/tree/v0.1.0)

_<sup>released at 2018-10-16 20:57:51 UTC</sup>_

First release of Artemis! <g-emoji class="g-emoji" alias="tada" fallback-src="https://github.githubassets.com/images/icons/emoji/unicode/1f389.png">&#127881;</g-emoji>

