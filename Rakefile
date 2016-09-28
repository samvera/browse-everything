#!/usr/bin/env rake
require 'bundler/gem_tasks'

Dir.glob('tasks/*.rake').each { |r| import r }

require 'rspec/core/rake_task'
require 'engine_cart/rake_task'
require 'jasmine'
load 'jasmine/tasks/jasmine.rake'

# Set up the test application prior to running jasmine tasks.
task 'jasmine:require' => :setup_test_server
task :setup_test_server do
  require 'engine_cart'
  EngineCart.load_application!
end

task default: [:ci]
