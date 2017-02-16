module Offeror

	def self.import(file, current, comment)
 		serialize_errors, serialized_codes = {submitted_codes: 0}, 0
 		serialize_errors[:err_file] = file_check(file.path)
 		return serialize_errors if serialize_errors[:err_file]
 		f = File.open(file.path, "r")
 			f.each_line do |row|
 				row = row.gsub(/\s+/, "") # eliminate spaces in a row
 				if row != ""   # don't get any blank code
          serialize_errors[:submitted_codes] += 1
          begin
            a = add_code(current, row)
            a.save!
            serialized_codes += 1
          rescue
            err_str = a.errors[:code].join(', ')
            serialize_errors[err_str] ||= []
            serialize_errors[err_str] << a.code
          end
            serialize_errors[:err_codes] =
              serialize_errors[:submitted_codes] - serialized_codes
				end
			end
		f.close
		
		@serialized_codes = serialized_codes
		@comment = comment
		update_history(current)
		current.update_attribute(:uploadedCodes, current.uploadedCodes + serialized_codes)
		current.update_attribute(:unclaimCodes, current.unclaimCodes + serialized_codes)
		
		return serialize_errors
	end
	
	def self.remove_unclaimed_codes(current)
		if current.class == Vendor
			unclaimedCodes = current.vendorCodes.where(:user_id => nil)
		else
			unclaimedCodes = current.redeemifyCodes.where(:user_id => nil)
		end
		
		num = current.unclaimCodes
		date = Time.now.to_formatted_s(:long_ordinal)
		
		history = current.history
		history = "#{history}#{date}\tCodes was removed\t-#{num}\n"
		current.update_attribute(:history, history)
		
		contents = "There are #{num} unclaimed codes, removed on #{date}\r\n\r\n"
		unclaimedCodes.each do |code|
			contents = "#{contents}#{code.code}\r\n"
			code.destroy
  	end
  	current.update_attribute(:unclaimCodes, 0)
  	current.update_attribute(:removedCodes, current.removedCodes + num)
  	
  	return contents
	end
	
	def self.home_set(histories)
		histories = histories.split(/\n/)
		histories_array = []
		histories.each do |history|
			temp = history.split(/\t/)
			histories_array.push(temp)
		end
		histories_array.reverse!
		return histories_array
	end
	
	private
	
  def self.add_code(offeror, code)
    if offeror.class == Vendor
      offeror.vendorCodes.build(:code => code, :name => offeror.name,
        :vendor => offeror)
    else
      offeror.redeemifyCodes.build(:code => code, :name => offeror.name,
        :provider => offeror)
    end
  end
  
  def self.update_history(offeror)
		history = offeror.history
		date = Time.now.to_formatted_s(:long_ordinal)
		if history == nil
			history = "#{date}\t#{@comment}\t#{@serialized_codes}\n"
		else
			history = "#{history}#{date}\t#{@comment}\t#{@serialized_codes}\n"
		end
		offeror.update_attribute(:history, history)
  end
  
  def self.file_check(file_path)
		return "Wrong file format! Please upload '.txt' file" unless file_path =~/.txt$/
		return "No codes detected! Please check your upload file" if File.zero? file_path
  end
end