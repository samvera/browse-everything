# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'browse_everything/version'

Gem::Specification.new do |spec|
  spec.name          = 'browse-everything'
  spec.version       = BrowseEverything::VERSION
  spec.authors       = ['Carolyn Cole', 'Jessie Keck', 'Michael B. Klein', 'Thomas Scherz', 'Xiaoming Wang', 'Jeremy Friesen']
  spec.email         = ['cam156@psu.edu', 'jkeck@stanford.edu', 'mbklein@gmail.com', 'scherztc@ucmail.uc.edu', 'xw5d@virginia.edu', 'jeremy.n.friesen@gmail.com']
  spec.description   = 'AJAX/Rails engine file browser for cloud storage services'
  spec.summary       = 'AJAX/Rails engine file browser for cloud storage services'
  spec.homepage      = 'https://github.com/projecthydra/browse-everything'
  spec.license       = 'Apache 2'

  spec.files         = `git ls-files -z`.split(/\000/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_dependency 'addressable', '~> 2.5'
  spec.add_dependency 'aws-sdk-s3'
  spec.add_dependency 'dropbox_api', '>= 0.1.20'
  spec.add_dependency 'google-apis-drive_v3'
  spec.add_dependency 'googleauth', '>= 0.6.6', '< 2.0'
  spec.add_dependency 'rails', '>= 4.2', '< 7.1'
  spec.add_dependency 'ruby-box'
  spec.add_dependency 'signet', '~> 0.8'
  spec.add_dependency 'typhoeus'

  spec.add_development_dependency 'bixby', '~> 5.0'
  spec.add_development_dependency 'bundler', '>= 1.3'
  spec.add_development_dependency 'capybara'
  spec.add_development_dependency 'engine_cart', '~> 2.2'
  spec.add_development_dependency 'factory_bot_rails'
  spec.add_development_dependency 'pry-byebug'
  spec.add_development_dependency 'rails-controller-testing'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rspec-its'
  spec.add_development_dependency 'rspec-rails'
  spec.add_development_dependency 'rspec_junit_formatter'
  spec.add_development_dependency 'rubocop-rspec'
  spec.add_development_dependency 'selenium-webdriver'
  spec.add_development_dependency 'sqlite3'
  spec.add_development_dependency 'webdrivers'
  spec.add_development_dependency 'webmock'
end
