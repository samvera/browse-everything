# frozen_string_literal: true

source 'https://rubygems.org'

# Specify your gem's dependencies in browse_everything.gemspec
gemspec

group :development, :test do
  gem 'pry-byebug' unless ENV['CI']
end

# BEGIN ENGINE_CART BLOCK
# engine_cart: 0.10.0
# engine_cart stanza: 0.10.0
# the below comes from engine_cart, a gem used to test this Rails engine gem in the context of a Rails app.
file = File.expand_path('Gemfile', ENV['ENGINE_CART_DESTINATION'] || ENV['RAILS_ROOT'] || File.expand_path('.internal_test_app', File.dirname(__FILE__)))
if File.exist?(file)
  Bundler.ui.warn "[EngineCart] here"

  begin
    eval_gemfile file
  rescue Bundler::GemfileError => e
    Bundler.ui.warn '[EngineCart] Skipping Rails application dependencies:'
    Bundler.ui.warn e.message
  end
else
  Bundler.ui.warn "[EngineCart] Unable to find test application dependencies in #{file}, using placeholder dependencies"

  if ENV['RAILS_VERSION']
    Bundler.ui.info "Installing Rails release #{ENV['RAILS_VERSION']}..."

    if ENV['RAILS_VERSION'] == 'edge'
      gem 'rails', github: 'rails/rails'
      ENV['ENGINE_CART_RAILS_OPTIONS'] = '--edge --skip-turbolinks'
    else
      gem 'rails', ENV['RAILS_VERSION']
    end
  end

  case ENV['RAILS_VERSION']
  when /^6\.1/
    gem 'puma', '~> 5.5'
  when /^6\.0/
    gem 'puma', '~> 4.1'
  when /^5\./
    gem 'capybara', '~> 2.18.0'
    gem 'puma', '~> 3.11'
  end
end
# END ENGINE_CART BLOCK

eval_gemfile File.expand_path('spec/test_app_templates/Gemfile.extra', File.dirname(__FILE__)) unless File.exist?(file)
