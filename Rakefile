require "bundler/gem_tasks"
require "rake/testtask"
require 'rspec/core/rake_task'

Rake::TestTask.new('test:isolated') do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList['test/**/*_test.rb']
  t.warning    = false
end

%w(
  integration
  unit
).each do |type|
  desc "Run the code examples in spec/#{type}"
  RSpec::Core::RakeTask.new("spec:#{type}") do |t|
    t.pattern = "./spec/#{type}/**/*_spec.rb"
  end
end

task default: ['spec:unit', 'test:isolated']
