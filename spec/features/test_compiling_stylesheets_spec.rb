# frozen_string_literal: true

describe 'Compiling the stylesheets', type: :feature, js: true do
  # This is a work-around until the support for sprockets is resolved
  xit 'does not raise errors' do
    visit '/'
    expect(page).not_to have_content 'Sass::SyntaxError'
  end
end
