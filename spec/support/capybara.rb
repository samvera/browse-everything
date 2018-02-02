# frozen_string_literal: true

require 'selenium-webdriver'

Capybara.javascript_driver = :headless_chrome

Capybara.register_driver :headless_chrome do |app|
  capabilities = Selenium::WebDriver::Remote::Capabilities.chrome(
    chromeOptions: { args: %w[headless disable-gpu no-sandbox] }
  )

  Capybara::Selenium::Driver.new(app,
                                 browser: :chrome,
                                 desired_capabilities: capabilities)
end

Capybara.default_max_wait_time = 5
