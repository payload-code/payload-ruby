require_relative "./request"

module Payload
	class ARMObject
		@poly = nil
		@data = nil
		@@cache = {}

		class << self
			attr_reader :spec, :poly, :data
		end

		def initialize(data)
			self.set_data(data)
		end

		def self.new(data)
			if data.key?('id') and @@cache.key?(data['id'])
				@@cache[data['id']].set_data(data)
				return @@cache[data['id']]
			else
				inst = super
				if data.key?('id') and not data['id'].nil? and not data['id'].empty?
					@@cache[data['id']] = inst
				end

				return inst
			end
		end

		def data
			@data
		end

		def set_data(data)
			@data = data
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

