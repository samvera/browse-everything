# frozen_string_literal: true

require 'selenium-webdriver'

# Temporary pin until chromedriver-helper patched to deal with change in chromedriver versioning
# See https://github.com/flavorjones/chromedriver-helper/pull/63
# @note In January 2018, TravisCI disabled Chrome sandboxing in its Linux
#       container build environments to mitigate Meltdown/Spectre
#       vulnerabilities, at which point Hyrax could no longer use the
#       Capybara-provided :selenium_chrome_headless driver (which does not
#       include the `--no-sandbox` argument).
Capybara.register_driver :selenium_chrome_headless_sandboxless do |app|
  browser_options = ::Selenium::WebDriver::Chrome::Options.new
  browser_options.args << '--headless'
  browser_options.args << '--disable-gpu'
  browser_options.args << '--no-sandbox'
  Capybara::Selenium::Driver.new(app, browser: :chrome, options: browser_options)
end

Capybara.default_max_wait_time = 5
Capybara.javascript_driver = :selenium_chrome_headless_sandboxless
