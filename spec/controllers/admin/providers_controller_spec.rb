require 'rails_helper'

describe Admin::ProvidersController do
  include Devise::Test::ControllerHelpers
  render_views
  
  before do
    @admin = create(:admin_user)
    @provider = create(:provider)
    sign_in(@admin)
  end
  
  describe "GET #index" do
    it "shows providers" do
      get :index
      expect(response.body).to have_content("example@google.com")
    end
  end
  
  describe "GET #edit" do
    it "allows edit provider details" do
      get :edit, { id: @provider }
      expect(response).to render_template(:edit)
    end
  end
  
  describe "POST #create" do
    it "creates provider" do
      expect{ post :create, provider: { name: "Amazon",
        email: "example@amazon.com" } }.to change{ Provider.count }.by(1)
    end
  end
  
  describe "DELETE #destroy" do
    it "removes provider" do
      expect{ delete :destroy, id: @provider }.
        to change{ Provider.count }.by(-1)
    end
  end
end