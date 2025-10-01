require "payload/version"
require "payload/objects"
require "payload/arm/session"

module Payload
	API_VERSIONS = [:v1, :v2].freeze
	@URL_LOOKUP = {
    v1: "https://api.payload.com",
    v2: "https://api.payload.com/v2"
  }.freeze
	
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
      version = version.to_sym if version.respond_to?(:to_sym)
      unless API_VERSIONS.include?(version)
        raise ArgumentError, "Invalid API version: #{version}. Must be one of: #{API_VERSIONS.join(', ')}"
      end
      @api_version = version
      # Reset session when version changes
      @session = nil
    end
    
    def api_version
      @api_version ||= :v1
    end
    
    def v1?
      api_version == :v1
    end
    
    def v2?
      api_version == :v2
    end

		def URL
			@URL_LOOKUP[@api_version]
		end

		private

    def session
      @session ||= Payload::Session.new(nil, @URL_LOOKUP[@api_version])
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
