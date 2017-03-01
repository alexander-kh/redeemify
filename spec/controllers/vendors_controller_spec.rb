require 'spec_helper'
require 'rails_helper'
 
describe VendorsController do

  describe "GET #home" do
    render_views
  
    it "renders profile, upload_page and view_codes templates" do
      expect(session[:vendor_id]).to be_nil
      v = Vendor.create :name => "thai" , :uid => "54321", :provider => "amazon"
      v.history = "April 3rd, 2015 23:51\tComment\t5\n"
      v.save!
      session[:vendor_id] = v.id
      expect(session[:vendor_id]).not_to be_nil
      get 'profile'
      expect(response).to render_template :profile
      get 'upload_page'
      expect(response).to render_template :upload_page
      get 'view_codes'
      expect(response).to render_template :view_codes
    end
    
    it "renders the home page showing vendor's provider" do
      amazon = FactoryGirl.create(:vendor)
      allow(controller).to receive(:current_vendor).and_return(amazon)
      get :home
      expect(response).to render_template(:home)
      expect(response.body).to match(/amazon_oauth2/i)
    end
  end

  describe "GET #edit" do
    it "renders edit template" do
      get :edit
      expect(response).to render_template :edit
    end
  end

  describe "GET #index" do
    it "renders index template" do
      get 'index'
      expect(response).to render_template :index
    end
  end

  describe "GET #upload_page" do
    render_views
    it "renders the upload page with the vendor provider" do
      amazon = FactoryGirl.create(:vendor)
      allow(controller).to receive(:current_vendor).and_return(amazon)
      get :upload_page
      expect(response).to render_template(:upload_page)
      expect(response.body).to match(/amazon_oauth2/i)
    end
  end
  
  describe "GET #profile" do
    render_views
    it "renders the profile page" do
      amazon = FactoryGirl.create(:vendor)
      allow(controller).to receive(:current_vendor).and_return(amazon)
      get :profile
      expect(response).to render_template(:profile)
      
      expect(response.body).to match("01/27/2015")
      expect(response.body).to match("AWS credit")
      expect(response.body).to match("https://aws.amazon.com/uk/awscredits/")
      expect(response.body).to match("Follow the page and redeem credit")
    end
  end

  describe "POST #import" do
    render_views
    before do
      @hash = {err_codes: 0, submitted_codes: 5}
      @err_hash = {err_codes: 2, submitted_codes: 5}
    end  

    it "renders the upload page and notifies user when no file is picked to upload" do
      post :import
      expect(response).to redirect_to(:vendors_upload_page)
      expect(flash[:error]).to eq("You have not selected a file to upload")
    end
    
    it "redirects to the home page and notifies user of codes successfully uploaded" do
      allow(Offeror).to receive(:import).and_return(@hash)
      post :import, file: !nil
      expect(response).to redirect_to(:vendors_home)
      expect(flash[:notice]).to match(/5 codes imported/)
    end
    
    it "calls #validation_errors_content to generate report content" do
      allow(Offeror).to receive(:import).and_return(@err_hash)
      expect(controller).to receive(:validation_errors_content).with(@err_hash)
      post :import, file: !nil
    end  

    it "calls #send_data prompting user to download error report" do
      content = "N codes submitted to update the code set"
      file = {filename: "#{@err_hash[:err_codes]}_codes_rejected_at_submission_details.txt"}
      allow(Offeror).to receive(:import).and_return(@err_hash)
      allow(controller).to receive(:validation_errors_content).with(@err_hash).and_return(content)
      expect(controller).to receive(:send_data).with(content, file) {controller.render nothing: true}
      post :import, file: !nil
    end  
  end
  
  describe "POST #update_profile" do
    before do
      @vendor = create(:vendor)
    end
    it "updates vendor profile" do
      expect(@vendor.cashValue).to eq("$10")
      allow(controller).to receive(:current_vendor).and_return(@vendor)
      post :update_profile, cash_value: "$15"
      expect(@vendor.cashValue).to eq("$15")
      expect(response).to redirect_to(:vendors_home)
      expect(flash[:notice]).to eq("Profile updated")
    end
  end
  
  describe "GET #remove_codes" do
    before do
      @vendor = create(:vendor)
      create_list(:vendor_code, 5, vendor_id: @vendor.id)
      @vendor.unclaimCodes = 5
    end
    it "removes unclaimed codes" do
      expect(@vendor.unclaimCodes).to eq(5)
      allow(controller).to receive(:current_vendor).and_return(@vendor)
      get :remove_codes
      expect(@vendor.unclaimCodes).to eq(0)
      expect(response).to redirect_to(:vendors_home)
      expect(flash[:notice]).to eq("Codes were removed")
    end
  end
  
  describe "GET #download_code" do
    before do
      @vendor = create(:vendor)
      create_list(:vendor_code, 5, vendor_id: @vendor.id)
    end
    it "downloads unclaimed codes" do
      unclaimed_codes = "unclaimed_codes"
      file = {filename: "unclaimed_codes.txt"}
      allow(controller).to receive(:current_vendor).and_return(@vendor)
      allow(Offeror).to receive(:download_codes).and_return(unclaimed_codes)
      expect(controller).to receive(:send_data).
        with(unclaimed_codes, file) {controller.render nothing: true}
      get :download_codes
    end
  end
  
  describe "GET #view_codes" do
    before do
      @vendor = create(:vendor)
    end
    it "renders view_codes template" do
      allow(controller).to receive(:current_vendor).and_return(@vendor)
      get :view_codes
      expect(response).to render_template(:view_codes)
    end
  end
  
  describe "GET #clear_history" do
    before do
      @vendor = create(:vendor)
    end
    it "clears history" do
      expect(@vendor.history).to eq("History")
      allow(controller).to receive(:current_vendor).and_return(@vendor)
      get :clear_history
      expect(@vendor.history).to be_nil
      expect(response).to redirect_to(:vendors_home)
      expect(flash[:notice]).to eq("History was cleared")
    end
  end
end