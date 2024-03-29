# frozen_string_literal: true

require 'rubocop/rake_task'

desc 'Run style checker'
RuboCop::RakeTask.new(:rubocop) do |task|
  task.fail_on_error = true
end

desc 'Run all RSpec tests.'
task ci: [:rubocop] do
  RSpec::Core::RakeTask.new(:spec)
  Rake::Task['spec'].invoke
end
