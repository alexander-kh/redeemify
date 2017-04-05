ActiveAdmin.register Vendor do
  menu :priority => 4
  permit_params :name, :email, :provider, :cash_value, :expiration, :website,
    :help_link, :instruction, :help, :expiration

  index do
    column :name
    column :email
    column "Log in through", :provider
    column :cash_value
    column :expiration
    column :website
    column "# Used Codes", :used_codes
    column "# Unclaimed Codes", :unclaimed_codes
    column "# Uploaded Codes", :uploaded_codes
    column "# Removed Codes", :removed_codes
    actions
  end
  config.filters = false

  form do |f|
    f.inputs "Vendor Details" do
      f.input :name
      f.input :email
      f.input :provider, label: 'Log in through', :as => :select, 
        :collection => { :Amazon => "amazon", :Google => "google_oauth2",
        :GitHub => "github", :Twitter => "twitter", :Facebook => "facebook" }
      f.input :cash_value
      f.input :expiration
      f.input :description
      f.input :website
      f.input :help_link
    end
    f.actions
  end
end
