# frozen_string_literal: true

source 'https://rubygems.org'

# Specify your gem's dependencies in browse_everything.gemspec
gemspec

group :development, :test do
  gem 'pry-byebug' unless ENV['CI']
end

# We allow testing under multiple versions of Rails by setting ENV RAILS_VERSION,
# used in CI, can be used locally too. Make sure to delete your Gemfile.lock after
# changing a local RAILS_VERSION
#
# TODO switch to use appraisal gem instead, encapsulating these different additional
# dependencies per Rails version, as well as method of choosing operative rails version.

if ENV['RAILS_VERSION']
  if ENV['RAILS_VERSION'] == 'edge'
    gem 'rails', github: 'rails/rails'
  else
    gem 'rails', ENV['RAILS_VERSION']
  end

  case ENV['RAILS_VERSION']
  when /^6\.0\./
    gem 'sass-rails', '>= 6'
    gem 'webpacker', '~> 4.0'
  when /^5\.[12]\./
    gem 'sass-rails', '~> 5.0'
    gem 'sprockets', '~> 3.7'
    gem 'thor', '~> 0.20'
  when /^7\.0\./
    # rspec-rails 6.0 is required for Rails 7 support, it's currently only in pre-release,
    # opt into it here. This should not be required when rspec-rails 6.0.0 final is released.
    # Note rspec-rails 6.0.0 does not support rails before 6.1, so different versions of
    # rspec-rails will be needed for different jobs, but that should happen automatically.
    gem "rspec-rails", ">= 6.0.0.rc1"
  end
end
