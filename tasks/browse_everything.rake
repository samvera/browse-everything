require 'engine_cart'

require 'pry-byebug'
namespace :browse_everything do

  desc "Create the test rails app"
  task :create_test_rails_app => ['engine_cart:setup'] do
    if EngineCart.fingerprint_expired?

      Rake::Task['engine_cart:create_test_rails_app'].invoke

      Bundler.unbundled_system("bundle install --quiet")

      Rake::Task['engine_cart:inject_gemfile_extras'].invoke

      within_test_app do
        bundle_webpacker = system("bundle exec rails webpacker:install")

        unless bundle_webpacker
          raise("EngineCart failed on with: #{$?}")
        end
      end
    end
  end

  desc "Generate the test rails app"
  task :generate_test_app => [:create_test_rails_app] do
    if EngineCart.fingerprint_expired?
      #binding.pry

      if File.exist? "#{EngineCart.templates_path}/lib/generators"
        Bundler.unbundled_system("cp -r #{EngineCart.templates_path}/lib/generators #{EngineCart.destination}/lib")
      end

      within_test_app do
        bundle_install_status = system("bundle install --quiet") || system("bundle update --quiet")
        #bundle_webpacker = system("bundle exec rails webpacker:install")
        bundle_rails = system("(bundle exec rails generate | grep test_app) && bundle exec rails generate test_app")
        bundle_rake = system("bundle exec rake db:migrate db:test:prepare")

        #unless bundle_install_status && bundle_webpacker && bundle_rails && bundle_rake
        unless bundle_install_status && bundle_rails && bundle_rake
          raise("EngineCart failed on with: #{$?}")
        end
      end

      Bundler.unbundled_system("bundle install --quiet")

      EngineCart.write_fingerprint
    end
  end
end
