require File.expand_path('../../../spec_helper',__FILE__)

describe 'browse_everything/_file.html.erb', type: :view do

  let(:file)  {
                BrowseEverything::FileEntry.new(
                     'file_id_01234', 'my_provider:/location/pa/th/file.m4v',
                     'file.m4v', 1024*1024*1024, Time.now, false
                   )
               }
  let(:provider) { double("provider") }
  let(:page) { Capybara::Node::Simple.new(rendered) }


  before do
    allow(view).to receive(:file).and_return(file)
    allow(view).to receive(:provider).and_return(provider)
    allow(view).to receive(:path).and_return("path")
    allow(view).to receive(:parent).and_return("parent")
    allow(view).to receive(:provider_name).and_return("my provider")
    allow(provider).to receive(:config).and_return(config)
    render
  end

  context "file not too big" do
    let(:config) { { max_upload_file_size: (5*1024*1024*1024) } }
    it "should draw link" do
      expect(page).to have_selector("a.ev-link")
    end
  end

  context "max not configured" do
    let(:config) { { } }
    it "should draw link" do
      expect(page).to have_selector("a.ev-link")
    end
  end

  context "file too big" do
    let(:config) { { max_upload_file_size: 1024 } }
    it "should draw link" do
      expect(page).not_to have_selector("a.ev-link")
    end
  end

end
