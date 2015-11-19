#!/usr/bin/env rake
require "bundler/gem_tasks"

Dir.glob('tasks/*.rake').each { |r| import r }

require 'rspec/core/rake_task'
require 'engine_cart/rake_task'

task :default => [:ci]
require 'jasmine'
load 'jasmine/tasks/jasmine.rake'
