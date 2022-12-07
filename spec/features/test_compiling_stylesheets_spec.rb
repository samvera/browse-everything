# frozen_string_literal: true

describe 'Compiling the stylesheets', type: :feature, js: true do
  #
  # The following error is raised for Ruby releases 2.6.z
  # Failure/Error: events = conf.options[:Silent] ? ::Puma::Events.strings : ::Puma::Events.stdio
  #
  # NoMethodError:
  #   undefined method `stdio' for Puma::Events:Class
  xit 'does not raise errors' do
    visit '/'
    expect(page).not_to have_content 'Sass::SyntaxError'
  end
end
