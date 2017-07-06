describe 'browse_everything/_file.html.erb', type: :view do
  let(:file) do
    BrowseEverything::FileEntry.new(
      'file_id_01234', 'my_provider:/location/pa/th/file.m4v',
      'file.m4v', 1024 * 1024 * 1024, Time.now, false
    )
  end
  let(:container) do
    BrowseEverything::FileEntry.new(
      'dir_id_01234', 'my_provider:/location/pa/th/dir',
      'dir', 0, Time.now, true
    )
  end
  let(:provider) { double('provider') }
  let(:page) { Capybara::Node::Simple.new(rendered) }

  before do
    allow(view).to receive(:browse_everything_engine).and_return(BrowseEverything::Engine.routes.url_helpers)
    allow(view).to receive(:provider).and_return(provider)
    allow(view).to receive(:path).and_return('path')
    allow(view).to receive(:parent).and_return('parent')
    allow(view).to receive(:provider_name).and_return('my provider')
    allow(provider).to receive(:config).and_return(config)
  end

  describe 'a file' do
    before do
      allow(view).to receive(:file).and_return(file)
      render
    end
    context 'file not too big' do
      let(:config) { { max_upload_file_size: (5 * 1024 * 1024 * 1024) } }
      it 'draws link' do
        expect(page).to have_selector('a.ev-link')
      end

      it 'provides hover text' do
        expect(page.find('td.ev-file')['title']).to eq(file.name)
      end
    end

    context 'max not configured' do
      let(:config) { {} }
      it 'draws link' do
        expect(page).to have_selector('a.ev-link')
      end
    end

    context 'file too big' do
      let(:config) { { max_upload_file_size: 1024 } }
      it 'draws link' do
        expect(page).not_to have_selector('a.ev-link')
      end
    end

    context 'multi-select' do
      let(:config) { {} }
      it 'does not have a checkbox' do
        expect(page).not_to have_selector('input.ev-select-all')
      end
    end
  end

  describe 'a directory' do
    before do
      allow(view).to receive(:file).and_return(container)
      render
    end
    context 'multi-select' do
      let(:config) { {} }
      it 'has the select-all checkbox' do
        expect(page).to have_selector('input.ev-select-all')
      end
    end
  end
end
