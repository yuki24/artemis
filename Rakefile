require "bundler/gem_tasks"
require 'rspec/core/rake_task'

%w(
  integration
  isolated
  unit
).each do |type|
  desc "Run the code examples in spec/#{type}"
  RSpec::Core::RakeTask.new("spec:#{type}") do |t|
    t.pattern = "./spec/#{type}/**/*_spec.rb"
  end
end

task default: ['spec:unit', 'spec:isolated']
