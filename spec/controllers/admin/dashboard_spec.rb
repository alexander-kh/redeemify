require 'rails_helper'

describe Admin::DashboardController do
  include Devise::Test::ControllerHelpers
  render_views
  
  describe "GET #index" do
    it "renders dashboard" do
      admin = create(:admin_user)
      sign_in(admin)
      get :index
      expect(response).to render_template(:index)
    end
  end
end