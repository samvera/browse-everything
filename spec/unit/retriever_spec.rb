require File.expand_path('../../spec_helper',__FILE__)

describe BrowseEverything::Retriever, vcr: { cassette_name: 'retriever', record: :none,  } do
  subject { BrowseEverything::Retriever.new }
  let(:datafile) { File.expand_path('../../fixtures/file_system/file_1.pdf',__FILE__) }
  let(:data) { File.open(datafile,'rb',&:read) }
  let(:size) { File.size(datafile) }

  context 'http://' do
    let(:spec) {
      { 
        "0" => {
          "url"=>"https://retrieve.cloud.example.com/some/dir/file.pdf", 
          "auth_header"=>{"Authorization"=>"Bearer ya29.kQCEAHj1bwFXr2AuGQJmSGRWQXpacmmYZs4kzCiXns3d6H1ZpIDWmdM8"}, 
          "expires"=>(Time.now + 3600).xmlschema, 
          "file_name"=>"file.pdf", 
          "file_size"=>size.to_s
        }
      }
    }
    
    context "#retrieve" do
      it "content" do
        content = ''
        subject.retrieve(spec['0']) { |chunk, retrieved, total| content << chunk }
        expect(content).to eq(data)
      end

      it "callbacks" do
        expect { |block| subject.retrieve(spec['0'], &block) }.to yield_with_args(data, data.length, data.length)
      end
    end
    
    context "#download" do
      it "content" do
        file = subject.download(spec['0'])
        expect(File.open(file,'rb',&:read)).to eq(data)
      end
      
      it "callbacks" do
        expect { |block| subject.download(spec['0'], &block) }.to yield_with_args(String, data.length, data.length)
      end
    end
  end
  
  context 'file://' do
    let(:spec) {
      { 
        "0" => {
          "url"=>"file://#{datafile}", 
          "file_name"=>"file.pdf", 
          "file_size"=>size.to_s
        }
      }
    }

    context "#retrieve" do
      it "content" do
        content = ''
        subject.retrieve(spec['0']) { |chunk, retrieved, total| content << chunk }
        expect(content).to eq(data)
      end

      it "callbacks" do
        expect { |block| subject.retrieve(spec['0'], &block) }.to yield_with_args(data, data.length, data.length)
      end
    end

    context "#download" do
      it "content" do
        file = subject.download(spec['0'])
        expect(File.open(file,'rb',&:read)).to eq(data)
      end
      
      it "callbacks" do
        expect { |block| subject.download(spec['0'], &block) }.to yield_with_args(String, data.length, data.length)
      end
    end
  end
  
  context ''
  
end
