RSpec.configure do |config|
  config.include Devise::Test::ControllerHelpers
  
  config.before(:all) do
    Warden.test_mode!
  end
  
  config.after(:all) do
    Warden.test_reset!
  end
end