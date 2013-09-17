desc "Run all RSpec tests."
task :ci do
  RSpec::Core::RakeTask.new(:spec)
  Rake::Task["app:clean"].invoke
  Rake::Task["app:generate"].invoke
  Rake::Task["spec"].invoke
end