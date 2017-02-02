class Vendor < ActiveRecord::Base
	# require 'csv'
	has_many :vendorCodes

	before_create :defaultValue

	def defaultValue
		self.usedCodes = 0
		self.uploadedCodes = 0
		self.unclaimCodes = 0
		self.removedCodes = 0
	end


  	def self.import(file, current, comment, type)
        
        serialize_errors, serialized_codes, date = {submitted_codes: 0}, 0, ""
        
        serialize_errors[:err_file] = file_check file.path
        return serialize_errors if serialize_errors[:err_file]
        
    	f = File.open(file.path, "r")
		f.each_line do |row|
			row = row.gsub(/\s+/, "")  # 12 3 4 --> 1234,
			if row !=  ""   # don't get any blank code
			  serialize_errors[:submitted_codes] +=1
			  begin	
				if type == "vendor"
			      	a = current.vendorCodes.build(:code => row, :name => current.name , :vendor => current)
                    a.save!
			    else
			    	a = current.redeemifyCodes.build(:code => row, :name => current.name , :provider => current)
			    	a.save!
			    end
			    serialized_codes += 1
			  rescue
			    err_str = a.errors[:code].join(', ')
			    serialize_errors[err_str] ||=[]
			    serialize_errors[err_str] << a.code
			  end
			    serialize_errors[:err_codes] = serialize_errors[:submitted_codes] - serialized_codes
			end
		end # end CSV.foreach
		f.close
		history = current.history

	    date = Time.now.to_formatted_s(:long_ordinal)
	    if history == nil
	    	history = "#{date}+++++#{comment}+++++#{serialized_codes.to_s}|||||"
	    else
	    	history = "#{history}#{date}+++++#{comment}+++++#{serialized_codes.to_s}|||||"
	    end
	    current.update_attribute(:history, history)
	    current.update_attribute(:uploadedCodes, current.uploadedCodes + serialized_codes)
	    current.update_attribute(:unclaimCodes, current.unclaimCodes + serialized_codes)

        return serialize_errors
        
  	end # end self.import(file)
  	
  	def self.file_check(file_path)
        return "Wrong file format! Please upload '.txt' file" unless file_path =~/.txt$/
        return "No codes detected! Please check your upload file" if File.zero? file_path
    end    
  		


  	def self.update_profile_vendor(current_vendor,info)
  		current_vendor.update_attributes(:cashValue => info["cashValue"], :expiration => info["expiration"], :helpLink => info["helpLink"],:instruction => info["instruction"], :description => info["description"])
  	end # end self.profile()

  	def self.remove_unclaimed_codes(current, type)
  		unclaimed = ""
  		if type == "vendor"
  			unclaimedCodes=current.vendorCodes.where(:user_id => nil)
  		else
  			unclaimedCodes=current.redeemifyCodes.where(:user_id => nil)
  		end

  		num = current.unclaimCodes
  		date = Time.now.to_formatted_s(:long_ordinal)

  		history = current.history
  		history = "#{history}#{date}+++++Delete Codes+++++-#{num.to_s}|||||"
  		current.update_attribute(:history, history)

  		contents = "There're #{num} unclaimed codes, remove on #{date}\n\n"
  		unclaimedCodes.each do |code|
  			contents = "#{contents}#{code.code}\n"
  			code.destroy
  		end
  		current.update_attribute(:unclaimCodes, 0)
  		current.update_attribute(:removedCodes, current.removedCodes + num)

  		return contents
  	end


  	def self.homeSet(histories)
		histories = histories.split("|||||")

		histories_array=[]
		histories.each do |history|
			temp = history.split("+++++")
			histories_array.push(temp)
		end
		histories_array.reverse!

	    return histories_array
  	end

    def serve_code(myUser)
    	code = self.vendorCodes.where(user: myUser).first || 
    	       self.vendorCodes.where(user: [0,nil]).first
        unless code.nil?
          if code.user_id.nil? && self.vendorCodes.find_by(user: myUser).nil?
            code.assign_to myUser
          end
        end
        code
    end   

end
