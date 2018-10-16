require "bundler/gem_tasks"
require "rake/testtask"
require 'rspec/core/rake_task'

Rake::TestTask.new('test:isolated') do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList['test/**/*_test.rb']
  t.warning    = false
end

RSpec::Core::RakeTask.new(:spec)

task default: ['spec', 'test:isolated']
