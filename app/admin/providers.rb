ActiveAdmin.register Provider do
  menu :priority => 3
  permit_params :name, :email, :provider
  
  index do
    column :name
    column :created_at
    column :email
    column "# Used Codes", :used_codes
    column "# Unclaimed Codes", :unclaimed_codes
    column "# Uploaded Codes", :uploaded_codes
    column "# Removed Codes", :removed_codes
    actions
  end
  config.filters = false

  form do |f|
    f.inputs "Provider Details" do
      f.input :name
      f.input :email
      f.input :provider, label: 'Log in through', :as => :select,
        :collection => { :Amazon => "amazon", :Google => "google_oauth2",
          :GitHub => "github", :Twitter => "twitter", :Facebook => "facebook" }
    end
    f.actions
  end
end
