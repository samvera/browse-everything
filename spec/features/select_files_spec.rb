# frozen_string_literal: true

describe 'Choosing files', type: :feature, js: true do
  before do
    visit '/'
  end

  shared_examples 'browseable files' do
    # This is a work-around until the support for Webpacker is resolved
    it 'selects files from the filesystem' do
      click_button('Browse')
      wait_for_ajax

      expect(page).to have_selector '#browse-everything'
      expect(page).to have_link 'config.ru'
      find(:css, '#config-ru').set(true)

      within('.modal-footer') do
        click_button('Submit')
      end

      wait_for_ajax

      expect(page).to have_selector('#status', text: '1 items selected')
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
