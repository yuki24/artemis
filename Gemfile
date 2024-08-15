source "https://rubygems.org"

git_source(:github) {|repo_name| "https://github.com/#{repo_name}" }

# Specify your gem's dependencies in artemis.gemspec
gemspec

gem 'pry'
gem 'pry-byebug', platforms: :mri
gem 'curb', '>= 0.9.6' if RUBY_ENGINE == 'ruby'
gem 'webrick' if RUBY_VERSION >= '3.0.0'
gem 'minitest', '< 5.25.0'
