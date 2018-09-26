
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "artemis/version"

Gem::Specification.new do |spec|
  spec.name          = "artemis"
  spec.version       = Artemis::VERSION
  spec.authors       = ["Yuki Nishijima"]
  spec.email         = ["yk.nishijima@gmail.com"]
  spec.summary       = %q{GraphQL on Rails}
  spec.description   = %q{GraphQL client on Rails + Convention over Configuration = ❤️}
  spec.homepage      = "https://github.com/yuki24/artemis"
  spec.license       = "MIT"
  spec.files         = `git ls-files -z`.split("\x0").reject {|f| f.match(%r{^(test)/}) }
  spec.require_paths = ["lib"]

  spec.add_dependency "graphql-client", ">= 0.13.0"

  spec.add_development_dependency "bundler", "~> 1.16"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "minitest", "~> 5.0"
end
