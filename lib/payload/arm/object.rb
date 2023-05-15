require "payload/arm/request"

module Payload
	class ARMObject
		@poly = nil
		@data = nil
		@@cache = {}
		@session = nil

		class << self
			attr_reader :spec, :poly, :data, :session
		end

		def initialize(data, session = nil)
			self.set_data(data)
		end

		def self.new(data, session = nil)

			session = session || Payload::Session.new(Payload::api_key, Payload::api_url)
			session_key = session.to_s

			if !@@cache.key?(session_key)
				@@cache[session_key] = {}
			end

			session_cache = @@cache[session_key]

			id = data.key?(:id) ? data[:id] : data.key?('id') ? data['id'] : nil
			if id && session_cache.key?(id)
				session_cache[id].set_data(data)
				return session_cache[id]
			else
				inst = super
				inst.set_session(session)
				inst.set_data(data)
				if id
					session_cache[id] = inst
				end

				return inst
			end
		end

		def session
			@session
		end

		def set_session(session)
			@session = session
		end

		def data
			@data
		end

		def set_data(data)
			@data = data.transform_keys { |key| key.to_s }
		end

		def method_missing(name, *args)
			attr = name.to_s
			if @data.key?(attr)
				return @data[attr]
			else
				super
			end
		end

		def [](key)
			return @data[key]
		end

		def _get_request()
			return Payload::ARMRequest.new(self.class, @session)
		end

		def self._get_request()
			return Payload::ARMRequest.new(self)
		end

		def self.select(*args, **data)
			return self._get_request().select(*args, **data)
		end

		def self.filter_by(*args, **data)
			return self._get_request().filter_by(*args, **data)
		end

		def self.create(*args, **data)
			if args.length != 0
				return self._get_request().create(args[0])
			else
				return self._get_request().create(data)
			end
		end

		def self.get(id)
			return self._get_request().get(id)
		end

		def self.delete(objects)
			return self._get_request().delete_all(objects)
		end

		def update(**update)
			return _get_request()._request('Put', id: self.id, json: update)
		end

		def delete()
			return _get_request()._request('Delete', id: self.id)
		end
	end
end
