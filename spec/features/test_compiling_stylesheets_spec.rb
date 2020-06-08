# frozen_string_literal: true

describe 'Compiling the stylesheets', type: :feature, js: true do
  #routes do
  #  Rails.application.class.routes
  #end

  it 'does not raise errors' do
    visit '/'
    expect(page).not_to have_content 'Sass::SyntaxError'
  end
end
