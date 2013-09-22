# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'browse_everything/version'

Gem::Specification.new do |spec|
  spec.name          = "browse-everything"
  spec.version       = BrowseEverything::VERSION
  spec.authors       = ["Michael Klein"]
  spec.email         = ["mbklein@gmail.com"]
  spec.description   = %q{AJAX file browser for cloud storage services}
  spec.summary       = %q{AJAX file browser for cloud storage services}
  spec.homepage      = "https://github.com/mbklein/browse-everything"
  spec.license       = "Apache 2"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "rails", ">= 3.1"
  spec.add_dependency "sass-rails"
  spec.add_dependency "bootstrap-sass"
  spec.add_dependency "font-awesome-rails"
  spec.add_dependency "google_drive"
  spec.add_dependency "dropbox-sdk"
  spec.add_dependency "skydrive"
  spec.add_dependency "ruby-box"
  spec.add_dependency "google-api-client"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "rspec-rails"
  spec.add_development_dependency "simplecov"
  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "webmock"
  spec.add_development_dependency "sqlite3"

end
