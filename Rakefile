#!/usr/bin/env rake
require "bundler/gem_tasks"

Dir.glob('tasks/*.rake').each { |r| import r }

ENV["RAILS_ROOT"] ||= 'spec/internal'

require 'rspec/core/rake_task'
require 'engine_cart/rake_task'

task :default => [:ci]
