require "bundler/gem_tasks"
require "rake/testtask"

TESTS_IN_ISOLATION = ['test/railtie_test.rb', 'test/rake_tasks_test.rb']

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.test_files = FileList['test/**/*_test.rb'] - TESTS_IN_ISOLATION
  t.warning    = false
end

Rake::TestTask.new('test:isolated') do |t|
  t.libs << "test"
  t.test_files = TESTS_IN_ISOLATION
  t.warning    = false
end

task default: ['test', 'test:isolated']
