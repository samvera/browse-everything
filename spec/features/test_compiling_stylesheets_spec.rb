# frozen_string_literal: true

describe 'Compiling the stylesheets', type: :feature do
  routes { Rails.application.class.routes }
  it 'does not raise errors' do
    visit '/'
    expect(page).not_to have_content 'Sass::SyntaxError'
  end
end
