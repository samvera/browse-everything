# frozen_string_literal: true

require 'open3'

# Run karma and parse the output for failures.
# The spec will fail if any karma test fails.
describe 'Karma' do
  let(:runner)  { Open3.capture3('karma', 'start') }
  let(:output)  { runner[0] + runner[1] }
  let(:status)  { runner[2].exitstatus }

  # This is a work-around until the support for sprockets is resolved
  xit 'expects all karma tests to pass' do
    $stderr.puts output unless status == 0
    expect(status).to eq(0)
  end
end
