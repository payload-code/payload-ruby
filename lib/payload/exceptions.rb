module Payload
	class PayloadError < StandardError
		@code = nil
		class << self
			attr_reader :code
		end

		def initialize(msg, details = nil)
			super(msg)
			@details = details
		end
	end

	class UnknownResponse < PayloadError
	end

	class BadRequest < PayloadError
		@code='400'
	end

	class InvalidAttributes < PayloadError
		@code='400'
	end

	class Unauthorized < PayloadError
		@code='401'
	end

	class Forbidden < PayloadError
		@code='403'
	end

	class NotFound < PayloadError
		@code='404'
	end

	class TooManyRequests < PayloadError
		@code='429'
	end

	class InternalServerError < PayloadError
		@code='500'
	end

	class ServiceUnavailable < PayloadError
		@code='503'
	end
end
