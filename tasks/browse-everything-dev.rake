namespace :app do
  desc "Create the test rails app"
  task :generate do
    unless File.exists?('spec/internal/Rakefile')
      puts "Generating rails app"
      `rails new spec/internal`
      puts "Updating gemfile"

      `echo "gem 'browse-everything', :path=>'../../../browse-everything'
  gem 'factory_girl_rails'
      " >> spec/internal/Gemfile`
      puts "Copying generator"
      `cp -r spec/support/lib/generators spec/internal/lib`
      Bundler.with_clean_env do
        within_test_app do
          puts "running test_app_generator"
          system "rails generate test_app"
          puts "Bundle install"
          `bundle install`
          puts "running migrations"
          puts `rake db:migrate db:test:prepare`
        end
      end
    end
    puts "Done generating test app"
  end

  desc "Clean out the test rails app"
  task :clean do
    puts "Removing sample rails app"
    `rm -rf spec/internal`
  end

  desc "Start the test rails app"
  task :start do
    Bundler.with_clean_env do
      within_test_app do
        puts "Starting test app"
        system "rails server -d"
      end
    end
  end

  desc "Stop the test rails app"
  task :stop do
    within_test_app do
      pid = File.read('tmp/pids/server.pid')
      puts "Stopping pid #{pid}"
      system "kill -2 #{pid}"
    end
  end
end

def within_test_app
  FileUtils.cd('spec/internal')
  yield
  FileUtils.cd('../..')
end