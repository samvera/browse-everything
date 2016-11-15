require 'spec_helper'

describe "Kaltura Driver", :vcr => { cassette_name: 'Kaltura_Session', record: :none  }  do

  context "starting a session", :vcr => { cassette_name: 'Kaltura_Session', record: :none  } do

     describe "should properly set and read config values" do
      before do
        Kaltura.configure do |config|
          config.partner_id = 1
          config.administrator_secret = 'superdupersecret'
          config.service_url = 'http://www.kaltura.com'
        end
      end

      it { Kaltura.config.partner_id.should == 1 }
      it { Kaltura.config.administrator_secret.should == 'superdupersecret' }
      it { Kaltura.config.service_url.should == 'http://www.kaltura.com' }
    end

    describe "should begin a session with proper credentials." do
       before do
        Kaltura.configure do |config|
          config.partner_id = 1
          config.administrator_secret = 'superdupersecret'
          config.service_url = 'http://www.kaltura.com'
        end
        @session = Kaltura::Session.start
      end

       it { @session.result.should be_an_instance_of String }
       it { Kaltura::Session.kaltura_session.should eq(@session.result) }
    end

    describe "should not begin a session with invalid credentials." do
       before do
         Kaltura.configure { |config| config.partner_id = 2 }
       end

       it { lambda {Kaltura::Session.start}.should raise_error Kaltura::KalturaError }
    end
  end
end
