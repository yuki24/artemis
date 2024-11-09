## Unreleased

#### 🚨 Breaking Changes

- No changes.

#### ⭐️ New Features

- Add support for Rails 8.0 ([<tt>#96</tt>](https://github.com/yuki24/artemis/pull/96))

#### 🐞 Bug Fixes

- No changes.

## [v1.1.0](https://github.com/yuki24/artemis/tree/v1.1.0)

_<sup>released at 2024-08-16 05:38:33 UTC</sup>_

#### ⭐️ New Features

- Add support for Ruby 3.3. ([<tt>e057567</tt>](https://github.com/yuki24/artemis/commit/e05756768c1535babccfca71f32d5218dd4da626))

## [v1.0.2](https://github.com/yuki24/artemis/tree/v1.0.2)

_<sup>released at 2024-05-02 02:41:10 UTC</sup>_

#### 🐞 Bug Fixes

- Fixes a bug where abstract client classes are not loaded correctly ([#93](https://github.com/yuki24/artemis/issues/93), `494d30b`)

## [v1.0.1](https://github.com/yuki24/artemis/tree/v1.0.1)

_<sup>released at 2024-05-02 02:40:54 UTC</sup>_

> Yanked due to inconsistent commit history.

## [v1.0.0](https://github.com/yuki24/artemis/tree/v1.0.0)

_<sup>released at 2024-02-05 06:16:35 UTC</sup>_

#### 🚨 Breaking Changes

- Drop support for Ruby 2.6. For those of you looking to use Artemis on Ruby 2.6, please use the `artemis` version
  `0.9.0` and the `graphql-client` version `0.17.0`. ([#90](https://github.com/yuki24/artemis/pull/90))

#### ⭐️ New Features

- Add support for Ruby 3.3. ([#91](https://github.com/yuki24/artemis/pull/91))
- Add support for the latest versions of the `graphql` gem. ([#92](https://github.com/yuki24/artemis/pull/92))

#### 🐞 Bug Fixes

- No bug fixes.

## [v0.9.0](https://github.com/yuki24/artemis/tree/v0.9.0)

_<sup>released at 2023-09-18 01:08:34 UTC</sup>_

#### New Features

- Rails 7.1.0.beta1 is now officially supported ([<tt>f25ba29</tt>](https://github.com/yuki24/artemis/commit/f25ba296f15b26ffba7e4ec0f5b4cbeb061c97a1))

#### Fixes

- Fixes an issue where `graphql` gem `2.1.0` may not work with `graphql-client` ([<tt>b144ee2</tt>](https://github.com/yuki24/artemis/commit/b144ee2fbca2c23b4aaed8236f6fc07f65d8239d))

## [v0.8.0](https://github.com/yuki24/artemis/tree/v0.8.0)

_<sup>released at 2023-01-05 05:29:37 UTC</sup>_

#### New Features

- Ruby 3.2 is now officially supported

## [v0.7.0](https://github.com/yuki24/artemis/tree/v0.7.0)

_<sup>released at 2022-03-05 08:24:45 UTC</sup>_

#### Features

- Add support for Ruby 3.1 and Rails 7.0
- Add support for [the Multiplex query](https://graphql-ruby.org/queries/multiplex.html)
- Do not allow the usage of the `multi_domain` adapter to be nested ([<tt>9b7b520</tt>](https://github.com/yuki24/artemis/commit/9b7b5202c9fbe424d4ca22f05dc9c9759b5202c3))
- Do not require fragment files to end with `_fragment.graphql` ([<tt>3c6c0fa</tt>](https://github.com/yuki24/artemis/commit/3c6c0fa))
- Allow for overriding the namespace used for resolving graphql file paths ([<tt>bd18762</tt>](https://github.com/yuki24/artemis/commit/bd18762))

## [v0.6.0](https://github.com/yuki24/artemis/tree/v0.6.0)

_<sup>released at 2021-09-03 04:17:55 UTC</sup>_

#### Features

- Add support for Ruby 3.0 and Rails 6.0, 6.1
- Add the multi domain adapter ([<tt>744b8ea</tt>](https://github.com/yuki24/artemis/commit/744b8ea35795b4e6cc4fdc1ebb63dd9a4e9819f0))

#### Fixes

- Address warnings from Ruby 2.7 ([<tt>408adcb</tt>](https://github.com/yuki24/artemis/commit/408adcb3f39912f7afb7b3690a52f1d593662b7b))
- Avoid crashing when config/graphql.yml does not exist ([@dlackty](https://github.com/dlackty), [#76](https://github.com/yuki24/artemis/pull/76))

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

First release of Artemis! 🎉

