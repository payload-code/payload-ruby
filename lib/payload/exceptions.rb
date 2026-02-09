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

	class TransactionDeclined < BadRequest
		attr_reader :transaction

		def initialize(msg, data = nil)
			super(msg, data)
			@transaction = if data && data['details'].is_a?(Hash)
				cls = Payload.get_cls(data['details'])
				cls = Payload::Transaction if cls.nil?
				cls.new(data['details'], nil)
			else
				nil
			end
		end
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
