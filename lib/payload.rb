require "payload/version"
require "payload/objects"
require "payload/arm/session"

module Payload
  @URL = "https://api.payload.com"
	
	class << self
		def api_key=(value)
			session.api_key = value
		end

		def api_key
			session.api_key
		end

		def api_url=(value)
			session.api_url = value
		end

		def api_url
			session.api_url
		end

    def api_version=(version)
      unless version.to_s =~ /\A\d+(\.\d)?\z/
        raise ArgumentError, "Version must be a number (as a string or numeric) with at most one optional decimal place, e.g. '1', '2.0', '1.5'"
      end
      @api_version = version
      # Reset session when version changes
      @session = nil
    end
    
    def api_version
      @api_version ||= 1
    end
    
		def URL
			@URL
		end

		private

    def session
      @session ||= Payload::Session.new(nil, @URL)
    end
	end

	def self.create(objects)
		return Payload::ARMRequest.new().create(objects)
	end

	def self.update(objects)
		return Payload::ARMRequest.new().update_all(objects)
	end

	def self.delete(objects)
		return Payload::ARMRequest.new().delete_all(objects)
	end

end
