# frozen_string_literal: true

describe 'browse_everything/_files.html.erb', type: :view do
  let(:file) do
    BrowseEverything::FileEntry.new(
      'file_id_01234', 'my_provider:/location/pa/th/file.m4v',
      'file.m4v', 1024 * 1024 * 1024, Time.current, false
    )
  end
  let(:container) do
    BrowseEverything::FileEntry.new(
      'dir_id_01234', 'my_provider:/location/pa/th/dir',
      'dir', 0, Time.current, true
    )
  end

  let(:provider) { instance_double(BrowseEverything::Driver::Base) }
  let(:page) { Capybara::Node::Simple.new(rendered) }
  let(:provider_contents_last_page) { false }
  let(:provider_contents_pages) { 1 }
  let(:provider_contents_current_page) { 0 }

  before do
    allow(view).to receive(:provider_contents_last_page?).and_return(provider_contents_last_page)
    allow(view).to receive(:provider_contents_pages).and_return(provider_contents_pages)
    allow(view).to receive(:provider_contents_current_page).and_return(provider_contents_current_page)
    allow(view).to receive(:browse_everything_engine).and_return(BrowseEverything::Engine.routes.url_helpers)
    allow(view).to receive(:provider).and_return(provider)
    allow(view).to receive(:path).and_return('path')
    allow(view).to receive(:parent).and_return('parent')
    allow(view).to receive(:provider_name).and_return('my provider')

    allow(provider).to receive(:config).and_return(config)

    allow(view).to receive(:provider_contents).and_return provider_contents
  end

  describe 'a file' do
    let(:config) { {} }
    let(:provider_contents) { [file] }

    before do
      allow(view).to receive(:file).and_return(file)
      render
    end

    context 'when a file is not too big' do
      let(:config) { { max_upload_file_size: (5 * 1024 * 1024 * 1024) } }

      it 'draws link' do
        expect(page).to have_selector('a.ev-link')
      end

      it 'provides hover text' do
        expect(page.find('td.ev-file')['title']).to eq(file.name)
      end
    end

    context 'when a maximum file size is not configured' do
      it 'draws link' do
        expect(page).to have_selector('a.ev-link')
      end
    end

    context 'when a file is too big' do
      let(:config) { { max_upload_file_size: 1024 } }

      it 'draws link' do
        expect(page).not_to have_selector('a.ev-link')
      end
    end

    it 'does not have a checkbox' do
      expect(page).not_to have_selector('input.ev-select-all')
    end
  end

  describe 'a directory' do
    let(:provider_contents) { [container] }

    before do
      allow(view).to receive(:file).and_return(container)
      render
    end

    it 'has the select-all checkbox' do
      expect(page).to have_selector('input.ev-select-all')
    end
  end
end
