require 'rails_helper'

RSpec.describe Vendor, :type => :model do
  # pending "add some examples to (or delete) #{__FILE__}"

  it 'sets correct cash value (#cashValue)' do
    vendor = FactoryGirl.create(:vendor)
    expect(vendor.cashValue).not_to eq("0.00")
  end

  it '#cashValue' do
    vendor = FactoryGirl.create(:vendor)
    expect(vendor.cashValue).to eq("$10")
  end
  
  describe '#serve_code' do
    before :all do
      @vendor = FactoryGirl.create :vendor
      @vendor.vendorCodes.create code: "MyCode"
      (1..3).each do |i| 
        @vendor.vendorCodes.create code: "000" + i.to_s,
          user: FactoryGirl.create(:user, email: "email_#{i}@domain.com")
      end  
      @myUser = FactoryGirl.create :user
    end  
    
    it "serves vendor code for new user" do
      expect(@vendor.serve_code @myUser).to be_truthy
      expect((@vendor.serve_code @myUser).code).to match(/MyCode/)
    end
    
    it "serves vendor code for returning user" do
      @vendor.serve_code @myUser
      expect((@vendor.serve_code @myUser).code).to match(/MyCode/)
    end
    
    it "returns nil when codes for a given vendor have already been served" do
      newUser = FactoryGirl.create :user, name: "Joe", email: "new@email.com"
      @vendor.serve_code @myUser
      expect(@vendor.serve_code newUser).to be_falsy
    end  
  end
  
    describe 'Vendor.import' do
      include Rack::Test::Methods
      include ActionDispatch::TestProcess
      
      before :all do
        
        @codes_file = fixture_file_upload("test.txt")
        @empty_file = fixture_file_upload("blank_test.txt")
        @er_file_format = fixture_file_upload("test.csv")
        @er_codes_file = fixture_file_upload("invalid_codes_test.txt")
        @vendor = FactoryGirl.create :vendor
        @provider = FactoryGirl.create :provider
        @comment = "Test Comment"
      end  
      
      it "updates Vendor set of codes by number of unique valid strings taken from upload file" do
        allow(Vendor).to receive(:file_check).with(any_args).and_return nil
        expect{Vendor.import(@codes_file, @vendor, @comment, "vendor")}.to change {@vendor.uploadedCodes}.by(3)
      end   
   
      it "updates Redeemify set of access codes by number of unique valid strings taken from upload file" do
        allow(Vendor).to receive(:file_check).with(any_args).and_return nil
        expect{Vendor.import(@codes_file, @provider, @comment, "provider")}.to change {@provider.uploadedCodes}.by(3)
      end   
   
      it "returns Vendor codes serializing report as a Hash" do
        allow(Vendor).to receive(:file_check).with(any_args).and_return nil
        expect(Vendor.import(@codes_file, @vendor, @comment, "vendor")).to be_an_instance_of Hash
      end
     
      it "returns Redeemify codes serializing report as a Hash" do
        allow(Vendor).to receive(:file_check).with(any_args).and_return nil
        expect(Vendor.import(@codes_file, @provider, @comment, "provider")).to be_an_instance_of Hash
      end
     
      it "returns, for Vendor codes, a Hash having :err_codes and :submitted_codes as keys" do
        allow(Vendor).to receive(:file_check).with(any_args).and_return nil
        expect(Vendor.import(@codes_file, @vendor, @comment, "vendor")).
               to match err_codes: an_instance_of(Fixnum),
                        submitted_codes: an_instance_of(Fixnum),
                        err_file: nil
      end
     
      it "returns, for Redeemify codes, a Hash having :errCodes and :submittedCodes as keys" do
        allow(Vendor).to receive(:file_check).with(any_args).and_return nil
        expect(Vendor.import(@codes_file, @provider, @comment, "provider")).
               to match err_codes: an_instance_of(Fixnum), 
                        submitted_codes: an_instance_of(Fixnum),
                        err_file: nil
      end
     
      it "returns, for Vendor codes, a Hash with validation errors as string keys each related to array of rejected codes" do
        allow(Vendor).to receive(:file_check).with(any_args).and_return nil
        expect(Vendor.import(@er_codes_file, @vendor, @comment, "vendor")).
              to match err_codes: an_instance_of(Fixnum), 
                       submitted_codes: an_instance_of(Fixnum),
                       err_file: nil,
                       "already registered" => an_instance_of(Array),
                       "longer than 255 characters" => an_instance_of(Array)
      end   
     
      it "returns, for Redeemify codes, a Hash with validation errors as string keys each related to array of rejected codes" do
        allow(Vendor).to receive(:file_check).with(any_args).and_return nil
        expect(Vendor.import(@er_codes_file, @provider, @comment, "provider")).
              to match err_codes: an_instance_of(Fixnum), 
                       submitted_codes: an_instance_of(Fixnum),
                       err_file: nil,
                       "already registered" => an_instance_of(Array),
                       "longer than 255 characters" => an_instance_of(Array)
      end
     
      it "receives a notification from :file_check of the wrong upload file format" do
        expect(Vendor).to receive(:file_check).with(@er_file_format.path).
               and_return "Wrong file format! Please upload '.txt' file"
        Vendor.import(@er_file_format, @vendor, @comment, "vendor")
      end
     
      it "receives a notification from :file_check of the empty upload file" do
        expect(Vendor).to receive(:file_check).with(@empty_file.path).
              and_return "No codes detected! Please check your upload file"
        Vendor.import(@empty_file, @vendor, @comment, "vendor")
      end   
    
      it "returns a Hash with :err_file notification of the empty upload file" do
        allow(Vendor).to receive(:file_check).with(any_args).
              and_return "No codes detected! Please check your upload file"
        expect(Vendor.import(@empty_file, @vendor, @comment, "vendor")).
              to match submitted_codes: 0, 
                       err_file: "No codes detected! Please check your upload file"
      end   

      it "returns a Hash with :err_file notification of the wrong file format" do
        allow(Vendor).to receive(:file_check).with(any_args).
              and_return "Wrong file format! Please upload '.txt' file"
        expect(Vendor.import(@er_file_format, @vendor, @comment, "vendor")).
              to match submitted_codes: 0, 
                       err_file: "Wrong file format! Please upload '.txt' file"
      end   
    end
end