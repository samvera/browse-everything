describe 'Choosing files', type: :feature, js: true do
  before do
    visit '/'
  end

  shared_examples 'browseable files' do
    it 'selects files from the filesystem' do
      click_button('Browse')
      wait_for_ajax
      expect(page).to have_selector '#browse-everything'
      expect(page).to have_link 'Gemfile.lock'
      click_link('Gemfile.lock')
      check('config-ru')
      wait_for_ajax
      within('.modal-footer') do
        expect(page).to have_selector('span', text: '2 files selected')
        click_button('Submit')
      end
      expect(page).to have_selector('#status', text: '2 items selected')
    end
  end

  context 'when Turbolinks are enabled' do
    before { click_link('Enter Test App (Turbolinks)') }
    it_behaves_like 'browseable files'
  end

  context 'when Turbolinks are disabled' do
    before { click_link('Enter Test App (No Turbolinks)') }
    it_behaves_like 'browseable files'
  end
end
