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
			@session = session || Payload::Session.new(Payload::api_key, Payload::api_url)
		end

		def self.new(data)
			id = data.key?(:id) ? data[:id] : data.key?('id')
			if id and @@cache.key?(id)
				@@cache[data[id]].set_data(data)
				return @@cache[id]
			else
				inst = super
				if id.nil? and not id.empty?
					@@cache[id] = inst
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

		def self.select(*args, **data)
			return Payload::ARMRequest.new(self).select(*args, **data)
		end

		def self.filter_by(*args, **data)
			return Payload::ARMRequest.new(self).filter_by(*args, **data)
		end

		def self.create(*args, **data)
			if args.length != 0
				return Payload::ARMRequest.new(self).create(args[0])
			else
				return Payload::ARMRequest.new(self).create(data)
			end
		end

		def self.get(id)
			return Payload::ARMRequest.new(self).get(id)
		end

		def self.delete(objects)
			return Payload::ARMRequest.new(self).delete(objects)
		end

		def update(**update)
			return Payload::ARMRequest.new(self.class)._request('Put', id: self.id, json: update)
		end

		def delete()
			return Payload::ARMRequest.new(self.class)._request('Delete', id: self.id)
		end
	end
end

