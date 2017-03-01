module Import
  
  def upload_page
  end

  def home
    @histories_array = []
    if current_offeror.history.present?
      @histories_array = Offeror.home_set(current_offeror.history)
    end

    @hash = { "uploaded" => current_offeror.uploadedCodes,
              "used" => current_offeror.usedCodes,
              "unclaimed" => current_offeror.unclaimCodes,
              "removed" => current_offeror.removedCodes }

    gon.codes = @hash
    gon.history = current_offeror.history
  end

  def import
    if params[:file].nil?
      redirect_to "/#{params[:controller]}/upload_page", 
        :flash => { :error => "You have not selected a file to upload" }
    else
      import_status = Offeror.import(params[:file], current_offeror,
                    params[:comment])
      fail_codes = import_status[:err_codes]
      if import_status[:err_file]
        flash[:error] = import_status[:err_file]
        redirect_to "/#{params[:controller]}/upload_page" 
      elsif fail_codes > 0
        content = validation_errors_content(import_status)
        send_data(content,
          :filename => "#{fail_codes}_#{'code'.pluralize(fail_codes)}_rejected_at_submission_details.txt")
      else                                
        flash[:notice] = "#{import_status[:submitted_codes]} #{'code'.pluralize(import_status[:submitted_codes])} imported" 
        redirect_to "/#{params[:controller]}/home"
      end
    end
  end
  
  def remove_codes
    flag = offeror_codes.where(:user_id => nil)
    if flag.count == 0
      redirect_to "/#{params[:controller]}/home",
        :flash => { :error => "There are no unclaimed codes" }
    else
      # contents = Offeror.remove_codes(current_offeror)
      # send_data contents, :filename => "unclaimed_codes.txt"
      Offeror.remove_codes(current_offeror)
      redirect_to "/#{params[:controller]}/home",
        :flash => { :notice => "Codes were removed" }
    end
  end
  
  def download_codes
    unclaimed_codes = Offeror.download_codes(current_offeror)
    send_data(unclaimed_codes, filename: "unclaimed_codes.txt")
  end
  
  def view_codes
    @offeror_codes = offeror_codes.all
  end

  def clear_history
    if current_offeror.history.nil?
      redirect_to "/#{params[:controller]}/home",
        :flash => { :error => "History is empty" }
    else
      current_offeror.update_attribute(:history, nil)
      redirect_to "/#{params[:controller]}/home",
        notice: "History was cleared"
    end
  end
end