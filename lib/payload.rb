require "payload/version"
require "payload/objects"

module Payload
	@URL = "https://api.payload.co"
	@api_url = @URL
	@api_key = nil

	class << self
		attr_accessor :api_key, :api_url
	end

	def self.create(objects)
		return Payload::ARMRequest.new().create(objects)
	end
end
