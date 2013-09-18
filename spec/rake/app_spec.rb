require "spec_helper"
require 'rake'

# saves original $stdout in variable
# set $stdout as local instance of StringIO
# yields to code execution
# returns the local instance of StringIO
# resets $stdout to original value
def capture_stdout
  out = StringIO.new
  $stdout = out
  yield
  return out.string
ensure
  $stdout = STDOUT
end

def loaded_files_excluding_current_rake_file
  $".reject { |file| file.include? "tasks/sufia-fixtures" }
end

describe "Rake Tasks" do
  before (:each) do
    @rake = Rake::Application.new
    Rake.application = @rake
    Rake.application.rake_require("browse-everything-dev", ["#{BrowseEverything::Engine.root}/tasks/"], loaded_files_excluding_current_rake_file)
    Rake::Task.define_task(:environment)
  end

  describe "start" do
    after (:each) do
      @rake['app:stop'].invoke
    end
    it "start an app" do
      o = capture_stdout do
        @rake['app:start'].invoke
      end
      o.should include "Starting"
      expect(File).to exist("spec/internal/tmp/pids/server.pid")
    end
  end

  describe "stop" do
    it "stop a started app" do

      o = capture_stdout do
        @rake['app:start'].invoke
      end

      #wait until the app has started
      while (!File.exists?('spec/internal/tmp/pids/server.pid'))
        sleep(0.01)
      end

      o = capture_stdout do
        @rake['app:stop'].invoke
      end
      o.should include "Stopping"
      attempts = 1
      while ((File.exists?('spec/internal/tmp/pids/server.pid')) && (attempts=+1 <20 ))
        sleep(0.01)
      end
      expect(File).not_to exist("spec/internal/tmp/pids/server.pid")
    end

    it "not fail when stopping a stopped app" do

      o = capture_stdout do
        @rake['app:stop'].invoke
      end
      expect(File).not_to exist("spec/internal/tmp/pids/server.pid")
    end
  end

  describe "clean" do
    after (:each) do
      @rake['app:generate'].invoke
      #wait until the app has generated
      while (!File.exists?('spec/internal/app/assets/stylesheets/'))
        sleep(0.01)
      end
    end

    it "remove spec internal app" do

      o = capture_stdout do
        @rake['app:clean'].invoke
      end
      expect(File).not_to exist("spec/internal/app")
    end

    it "stop server" do
      o = capture_stdout do
        @rake['app:start'].invoke
      end

      #wait until the app has started
      while (!File.exists?('spec/internal/tmp/pids/server.pid'))
        sleep(0.01)
      end

      o = capture_stdout do
        @rake['app:clean'].invoke
      end
      o.should include "Stopping"
      expect(File).not_to exist("spec/internal/app")

    end

  end

end