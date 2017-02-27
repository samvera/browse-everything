describe 'Compiling the stylesheets', type: :feature do
  it 'does not raise errors' do
    visit '/'
    expect(page).not_to have_content 'Sass::SyntaxError'
  end
end
