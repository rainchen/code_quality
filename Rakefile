require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec) # introduce `rake spec` to Run RSpec code examples

task :default => :spec
task :test => :spec # alias `rake test`
Rake::Task.send :load, 'tasks/code_quality.rake'
