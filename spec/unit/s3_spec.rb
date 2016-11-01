include BrowserConfigHelper

describe BrowseEverything::Driver::FileSystem do
  before(:all)  { stub_configuration   }
  after(:all)   { unstub_configuration }
  let(:browser) { BrowseEverything::Browser.new(url_options) }
  let(:provider) { browser.providers['s3'] }

  it '#validate_config' do
    expect { BrowseEverything::Driver::S3.new({}) }.to raise_error(BrowseEverything::InitializationError)
  end

  describe '#contents' do
    context 'root directory' do
      before do
        Aws.config[:s3] = {
          stub_responses: {
            list_objects: { is_truncated: false, marker: "", next_marker: nil, contents: [], name: "s3.bucket", prefix: "", delimiter: "/", max_keys: 1000, common_prefixes: [ { prefix: 'foo/' }, { prefix: 'bar/'} ], encoding_type: "url" },
          }
        }
      end
      
      let(:contents) { provider.contents('') }
      context '[0]' do
        subject { contents[0] }
        its(:name) { should == 'bar'     }
        specify    { should be_container }
      end
      context '[1]' do
        subject { contents[1] }
        its(:name) { should == 'foo'     }
        specify    { should be_container }
      end
    end
    
    context 'subdirectory' do
      before do
        Aws.config[:s3] = {
          stub_responses: {
            list_objects: 
              {
                is_truncated: false, marker: "", next_marker: nil, name: "s3.bucket", prefix: "foo/", delimiter: "/", max_keys: 1000, common_prefixes: [], encoding_type: "url",
                contents: [
                  { key: "foo/", last_modified: Time.parse('2014-02-03 16:27:01 UTC'), etag: "\"d41d8cd98f00b204e9800998ecf8427e\"", size: 0, storage_class: "STANDARD", owner: { display_name: "mbklein" } },
                  { key: "foo/baz.jpg", last_modified: Time.parse('2016-10-31 20:12:32 UTC'), etag: "\"4e2ad532e659a65e8f106b350255a7ba\"", size: 52645, storage_class: "STANDARD", owner: { display_name: "mbklein" } },
                  { key: "foo/quux.png", last_modified: Time.parse('2016-10-31 22:08:12 UTC'), etag: "\"a92bbe23736ebdbd37bdc795e7d570ad\"", size: 1511860, storage_class: "STANDARD", owner: { display_name: "mbklein" } }
                ]
              }
          }
        }
      end
      
      let(:contents) { provider.contents('foo/') }
      context '[0]' do
        subject { contents[0] }
        its(:name) { should == '..'      }
        specify    { should be_container }
      end
      context '[1]' do
        subject { contents[1] }
        its(:name)     { should == 'baz.jpg' }
        its(:location) { should == "s3:foo/baz.jpg"  }
        its(:type)     { should == 'image/jpeg'      }
        its(:size)     { should == 52645             }
        specify        { should_not be_container     }
      end
      context '[2]' do
        subject { contents[2] }
        its(:name)     { should == 'quux.png' }
        its(:location) { should == "s3:foo/quux.png" }
        its(:type)     { should == 'image/png'       }
        its(:size)     { should == 1511860           }
        specify        { should_not be_container     }
      end
    end
  end
end
