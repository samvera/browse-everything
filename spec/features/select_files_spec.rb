require 'capybara/poltergeist'

describe 'Choosing files', type: :feature do
  before do
    Capybara.register_driver :poltergeist do |app|
      Capybara::Poltergeist::Driver.new(app, js_errors: true, timeout: 90)
    end
    Capybara.current_driver = :poltergeist
    visit '/'
  end

  shared_examples 'browseable files' do
    it 'selects files from the filesystem' do
      click_button('Browse')
      sleep(5)
      click_link('Gemfile.lock')
      check('config-ru')
      within('.modal-footer') do
        expect(page).to have_selector('span', text: '2 files selected')
        click_button('Submit')
      end
      sleep(5)
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
