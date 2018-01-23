require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

task :default => :spec
Rake::Task.send :load, 'tasks/code_quality.rake'
