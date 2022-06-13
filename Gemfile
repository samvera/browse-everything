# frozen_string_literal: true

source 'https://rubygems.org'

# Specify your gem's dependencies in browse_everything.gemspec
gemspec

group :development, :test do
  gem 'pry-byebug' unless ENV['CI']
end

# BEGIN ENGINE_CART BLOCK
# engine_cart: 2.4.0
# engine_cart stanza: 2.5.0
# the below comes from engine_cart, a gem used to test this Rails engine gem in the context of a Rails app.
file = File.expand_path('Gemfile', ENV['ENGINE_CART_DESTINATION'] || ENV['RAILS_ROOT'] || File.expand_path('.internal_test_app', File.dirname(__FILE__)))
if File.exist?(file)
  begin
    eval_gemfile file
  rescue Bundler::GemfileError => e
    Bundler.ui.warn '[EngineCart] Skipping Rails application dependencies:'
    Bundler.ui.warn e.message
  end
else
  Bundler.ui.warn "[EngineCart] Unable to find test application dependencies in #{file}, using placeholder dependencies"

  if ENV['RAILS_VERSION']
    if ENV['RAILS_VERSION'] == 'edge'
      gem 'rails', github: 'rails/rails'
      ENV['ENGINE_CART_RAILS_OPTIONS'] = '--edge --skip-turbolinks'
    else
      gem 'rails', ENV['RAILS_VERSION']
    end

    case ENV['RAILS_VERSION']
    when /^6.0/
      gem 'sass-rails', '>= 6'
      gem 'webpacker', '~> 4.0'
    when /^5.[12]/
      gem 'sass-rails', '~> 5.0'
      gem 'sprockets', '~> 3.7'
      gem 'thor', '~> 0.20'
    end
  end
end
# END ENGINE_CART BLOCK

# rspec-rails 6.0 is required for Rails 7 support, it's currently only in pre-release,
# opt into it here. This should not be required when rspec-rails 6.0.0 final is released.
# Note rspec-rails 6.0.0 does not support rails before 6.1, so different versions of
# rspec-rails will be needed for different jobs, but that should happen automatically.
if ENV['RAILS_VERSION'] && ENV['RAILS_VERSION'] =~ /^7\.0\./
  gem "rspec-rails", ">= 6.0.0.rc1"
end
