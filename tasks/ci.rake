desc "Run all RSpec tests."
task :ci => ['engine_cart:generate'] do
  RSpec::Core::RakeTask.new(:spec)
  Rake::Task["spec"].invoke
end
