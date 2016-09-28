require 'rake'

# Run the jasmine tests by running the jasmine:ci rake command and parses the output for failures.
# The spec will fail if any jasmine tests fails.
describe 'Jasmine' do
  it 'expects all jasmine tests to pass' do
    load_rake_environment ["#{jasmine_path}/lib/jasmine/tasks/jasmine.rake"]
    jasmine_out = run_task 'jasmine:ci'
    unless jasmine_out.include? '0 failures'
      puts 'Some of the Jasmine tests failed'
      puts jasmine_out
    end
    expect(jasmine_out).to include '0 failures'
  end
end

def jasmine_path
  Gem.loaded_specs['jasmine'].full_gem_path
end
