# frozen_string_literal: true

source 'https://rubygems.org'

# Specify your gem's dependencies in browse_everything.gemspec
gemspec

group :development, :test do
  gem 'pry-byebug' unless ENV['CI']
end

# == Extra dependencies for dummy test app ==
#
# Extra dependencies for dummy test app are in .gemspec as a development dependency
# where possible. But when  dependencies vary for different versions
# of Rails, rails-version-specific dependencies are here, behind conditionals, for now.
#
# TODO switch to use appraisal gem instead, encapsulating these different additional
# dependencies per Rails version, as well as method of choosing operative rails version.
#
# We allow testing under multiple versions of Rails by setting ENV RAILS_VERSION,
# used in CI, can be used locally too.

# Set a default RAILS_VERSION so we make sure to get extra dependencies for it...

ENV['RAILS_VERSION'] ||= "7.0.3"

if ENV['RAILS_VERSION']
  if ENV['RAILS_VERSION'] == 'edge'
    gem 'rails', github: 'rails/rails'
  else
    gem 'rails', ENV['RAILS_VERSION']
  end

  case ENV['RAILS_VERSION']
  when /^7\.0\./
    # rspec-rails 6.0 is required for Rails 7 support, it's currently only in pre-release,
    # opt into it here. This should not be required when rspec-rails 6.0.0 final is released.
    # Note rspec-rails 6.0.0 does not support rails before 6.1, so different versions of
    # rspec-rails will be needed for different jobs, but that should happen automatically.
    gem "rspec-rails", ">= 6.0.0.rc1"

    # sprockets is optional for rails 7, but we currently require it, and test with it.
    gem "sprockets-rails"
  when /^6\.1\./
    # opt into mail 2.8.0.rc1 so we get extra dependencies required for rails 6.1
    # Once mail 2.8.0 final is released this will not be required.
    # https://github.com/mikel/mail/pull/1472
    gem "mail", ">= 2.8.0.rc1"
  when /^6\.0\./
    gem 'sass-rails', '>= 6'
  when /^5\.[12]\./
    gem 'sass-rails', '~> 5.0'
    gem 'sprockets', '~> 3.7'
    gem 'thor', '~> 0.20'
  end
end
