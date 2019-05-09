# frozen_string_literal: true

require 'selenium-webdriver'

# Temporary pin until chromedriver-helper patched to deal with change in chromedriver versioning
# See https://github.com/flavorjones/chromedriver-helper/pull/63
Capybara.register_driver :selenium_chrome_headless_sandboxless do |app|
  browser_options = ::Selenium::WebDriver::Chrome::Options.new
  browser_options.args << '--headless'
  browser_options.args << '--disable-gpu'
  browser_options.args << '--no-sandbox'
  Capybara::Selenium::Driver.new(app, browser: :chrome, options: browser_options)
end

Capybara.default_max_wait_time = 5
Capybara.javascript_driver = :selenium_chrome_headless_sandboxless
