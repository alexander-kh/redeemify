require 'rails_helper'

describe Admin::AdminUsersController do
  include Devise::Test::ControllerHelpers
  render_views
  
  before do
    @admin = create(:admin_user)
    sign_in(@admin)
  end
  
  describe "GET #index" do
    it "shows admin in the index" do
      get :index
      expect(response.body).to have_content("admin@redeemify.com")
    end
  end
  
  describe "POST #create" do
    it "creates new admin" do
      expect{ post :create, admin_user: { email: "new_admin@redeemify.com",
        password: "password" } }.to change{ AdminUser.count }.by(1)
    end
  end
  
  describe "GET #update" do
    it "allows edit admin details" do
      get :edit, { id: @admin }
      expect(response).to render_template(:edit)
    end
  end
  
  describe "PATCH #update" do
    it "updates admin details" do
      patch :update, { id: @admin,
        admin_user: { email: "admin@strawberrycanyon.com" } }
      @admin.reload
      expect(@admin.email).to eq("admin@strawberrycanyon.com")
    end
  end
end