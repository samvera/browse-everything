# frozen_string_literal: true

require 'selenium-webdriver'

Capybara.javascript_driver = :headless_chrome

Capybara.register_driver :headless_chrome do |app|
  options = Selenium::WebDriver::Chrome::Options.new

  options.add_argument('--headless')
  options.add_argument('--disable-gpu')
  options.add_argument('--no-sandbox')
  options.add_argument('--disable-dev-shm-usage')
  options.add_argument('--start-maximized')
  Capybara::Selenium::Driver.new(app,
                                 browser: :chrome,
                                 options: options)
end

Capybara.default_max_wait_time = 5

RSpec.configure do |config|
  config.before(:each, type: :system, js: true) do
    driven_by :headless_chrome
  end
end
