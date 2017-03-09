class SessionsController < ApplicationController
  
  def new
    if session[:vendor_id].present?
      @vendor_user = session[:vendor_id]
    end
  end

  def create
    auth = request.env["omniauth.auth"]
    
    offeror = Provider.find_by_provider_and_email(auth["provider"], 
      auth["info"]["email"]) || Vendor.find_by_provider_and_email(
      auth["provider"], auth["info"]["email"])
    
    if offeror.present?
      log_in(offeror)
      redirect_to "/#{offeror.class.to_s.downcase}s/home",
        notice: "Welcome, #{offeror.name}"
    else
      user = User.find_by_provider_and_email(auth["provider"], auth["uid"]) ||
        User.create_with_omniauth(auth)
      log_in(user)
      if user.code.present?
        redirect_to '/sessions/customer'
      else
        redirect_to '/sessions/new', notice: "Signed in!"
      end
    end
  end

  def customer
    if session[:user_id]
      if current_user.code.nil?
        unless RedeemifyCode.serve(current_user, params[:code])
          flash.now[:error] = 
            'Your code is either invalid or has been redeemed already.
              <br>Please enter a valid redeemify code.'.html_safe
          render :new ; return
        end
      end
      set_vendor_code(current_user)
    end
    if session[:vendor_id].present?
      @vendor_user = session[:vendor_id]
    end
  end
  
  def delete_page
  end

  def delete_account
    if current_user.present?
      current_user.anonymize!
      RedeemifyCode.anonymize! current_user
      VendorCode.anonymize_all! current_user
      
      session.delete(:user_id)
      redirect_to root_url, notice: "Your account has been deleted"
    end
  end

  def destroy
    session.delete(:user_id)
    session.delete(:vendor_id)
    session.delete(:provider_id)
    gon.clear
    redirect_to root_url, notice: "Signed out!"
  end

  def failure
    redirect_to root_url, alert: "Authentication failed, please try again"
  end

  def change_to_vendor
    session[:user_id] = nil
    redirect_to '/vendors/home', notice: "Changed to vendor account"
  end

  private
  
  def log_in(user)
    key = "#{user.class.to_s.downcase}_id".to_sym
    session[key] = user.id
  end
  
	def set_vendor_code(current_user)
		@list_codes, @instruction, @description, @help, @expiration, @website,
		@cash_value, @total = {}, {}, {}, {}, {}, {}, {}, 0
		@current_code = current_user.code
		vendors = Vendor.all
		vendors.each do |vendor|
			vendor_code = vendor.serve_code(current_user)
			flash.now[:alert] = 'Some offers are not available at this time,
				please come back later' unless vendor_code
			@list_codes[vendor.name] ||= 
			  vendor_code ? vendor_code.code : 'Not available'
			@instruction[vendor.name] ||= vendor.instruction
			@help[vendor.name] ||= vendor.helpLink
			@expiration[vendor.name] ||= vendor.expiration
			@website[vendor.name] ||= vendor.website
			@cash_value[vendor.name] ||= vendor.cashValue
			@description[vendor.name] ||= vendor.description
			@total += vendor.cashValue.gsub(/[^0-9\.]/,'').to_f
			@total = @total.round(2)
		end
	end
end
