require 'rails_helper'
require 'spec_helper'

describe Admin::AdminUsersController do
  render_views
  
  before do
    admin = create(:admin_user)
    sign_in(admin)
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
end